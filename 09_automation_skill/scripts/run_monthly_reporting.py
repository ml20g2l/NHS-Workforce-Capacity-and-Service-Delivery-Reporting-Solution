"""Controlled monthly reporting runner for the NHS public-data workflow.

The runner is deliberately conservative: it creates an audit trail before
producing reportable facts and exits on a critical input or schema failure.
"""

import argparse
import csv
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path


WORKFORCE_REQUIRED = {"Date", "Org Code", "Org Name", "Staff Group", "Data Type", "Total"}
ABSENCE_REQUIRED = {"DATE", "ORG_CODE", "ORG_NAME", "FTE_DAYS_LOST", "FTE_DAYS_AVAILABLE", "SICKNESS_ABSENCE_RATE_PERCENT"}
ACTIVITY_REQUIRED = {"Period", "Org Code", "Org name"}
PROVENANCE = ["SourceFile", "SourceDataset", "ReportingMonth", "LoadTimestamp", "RecordStatus", "ValidationReason"]
MONTH_PATTERN = re.compile(r"(20\d{2})[-_](0[1-9]|1[0-2])")


class CriticalValidationError(Exception):
    pass


def as_float(value):
    try:
        return float(str(value).strip().replace(",", ""))
    except (TypeError, ValueError):
        return None


def source_files(value):
    path = Path(value)
    if not path.exists():
        raise CriticalValidationError(f"Input does not exist: {path}")
    files = [path] if path.is_file() else sorted(path.glob("*.csv"))
    if not files:
        raise CriticalValidationError(f"No CSV files found: {path}")
    return [file for file in files if not file.name.startswith("~")]


def month_from_filename(path):
    match = MONTH_PATTERN.search(path.name)
    if not match:
        return None
    return f"{match.group(1)}-{match.group(2)}-01"


def month_from_source_value(value):
    text = str(value or "").strip()
    for pattern in ("%d/%m/%Y", "%Y-%m-%d", "%Y-%m-%d %H:%M:%S"):
        try:
            return datetime.strptime(text, pattern).strftime("%Y-%m-01")
        except ValueError:
            continue
    return None


def file_fingerprint(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def reconcile_previous(previous_refresh, current_rows):
    if not previous_refresh:
        return current_rows, "Not available"
    previous_path = Path(previous_refresh)
    previous_file = previous_path / "reconciliation_report.csv" if previous_path.is_dir() else previous_path
    if not previous_file.is_file():
        return current_rows, "Not available: prior reconciliation file not found"
    try:
        with previous_file.open("r", encoding="utf-8-sig", newline="") as handle:
            previous = {row.get("Dataset"): row for row in csv.DictReader(handle) if row.get("Dataset")}
        for row in current_rows:
            prior = previous.get(row["Dataset"])
            if prior:
                for field in ("RawRows", "AcceptedRows", "RejectedRows", "ReviewRequiredRows"):
                    prior_value = int(float(prior.get(field, 0) or 0))
                    current_value = int(row[field])
                    row[f"Previous{field}"] = prior_value
                    row[f"Difference{field}"] = current_value - prior_value
        return current_rows, "Compared"
    except (OSError, ValueError, csv.Error):
        return current_rows, "Not available: prior reconciliation unreadable"


def read_csv_checked(path, required, dataset):
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        headers = set(reader.fieldnames or [])
        missing = sorted(required - headers)
        if missing:
            raise CriticalValidationError(f"{dataset}: {path.name} missing required columns: {', '.join(missing)}")
        return list(reader), headers


def load_reference(path):
    rows, headers = read_csv_checked(
        path,
        {"OrganisationCode", "CanonicalOrganisationName", "InclusionFlag"},
        "Organisation reference",
    )
    reference = {}
    for row in rows:
        code = (row["OrganisationCode"] or "").strip().upper()
        if not code or code in reference:
            raise CriticalValidationError("Organisation reference has a blank or duplicate OrganisationCode")
        flag = (row["InclusionFlag"] or "").strip().lower()
        if flag not in {"true", "false"}:
            raise CriticalValidationError(f"Organisation reference has invalid InclusionFlag for {code}")
        reference[code] = row
    return reference


def log_record(logs, **values):
    logs.append(values)


def status_for_code(code, reference):
    if not code:
        return "Rejected", "Organisation code is missing"
    if code not in reference:
        return "Review Required", "Organisation code not found in approved reference"
    if reference[code]["InclusionFlag"].strip().lower() != "true":
        return "Review Required", "Organisation is outside the approved reporting cohort"
    return "Accepted", ""


def run(args):
    output = Path(args.output_dir)
    output.mkdir(parents=True, exist_ok=True)
    refresh_id = datetime.now(timezone.utc).strftime("REFRESH-%Y%m%dT%H%M%SZ")
    timestamp = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    logs, processed, inventory = [], [], []
    try:
        if not Path(args.kpi_dictionary).is_file():
            raise CriticalValidationError("KPI dictionary is missing or unreadable")
        reference = load_reference(Path(args.organisation_reference))
        inputs = {
            "Workforce": (source_files(args.workforce), WORKFORCE_REQUIRED),
            "Absence": (source_files(args.absence), ABSENCE_REQUIRED),
            "Service Activity": (source_files(args.activity), ACTIVITY_REQUIRED),
        }
        duplicate_files = set()
        for dataset, (files, _) in inputs.items():
            grouped = defaultdict(list)
            for file in files:
                period = month_from_filename(file)
                grouped[period].append(file)
                inventory.append({"SourceDataset": dataset, "SourceFile": file.name, "ReportingMonth": period, "SourceSizeBytes": file.stat().st_size, "ContentFingerprint": file_fingerprint(file)})
            for period, period_files in grouped.items():
                if len(period_files) > 1:
                    duplicate_files.update(period_files)
        for dataset, (files, required) in inputs.items():
            for file in files:
                if not month_from_filename(file):
                    raise CriticalValidationError(f"{dataset}: reporting month not recognised in filename: {file.name}")
                rows, headers = read_csv_checked(file, required, dataset)
                if dataset == "Service Activity" and not any(h.startswith("A&E attendances") for h in headers):
                    raise CriticalValidationError(f"{dataset}: no A&E attendance columns found in {file.name}")
                if dataset == "Service Activity" and not any(h.startswith("Attendances over 4hrs") for h in headers):
                    raise CriticalValidationError(f"{dataset}: no over-four-hour columns found in {file.name}")
                if dataset == "Service Activity" and not any(h.startswith("Emergency admissions") for h in headers):
                    raise CriticalValidationError(f"{dataset}: no emergency-admission columns found in {file.name}")
                period = month_from_filename(file)
                for row_number, row in enumerate(rows, start=2):
                    code_field = "ORG_CODE" if dataset == "Absence" else "Org Code"
                    original_code = (row.get(code_field) or "").strip()
                    code = original_code.upper()
                    status, reason = status_for_code(code, reference)
                    source_period_field = "DATE" if dataset == "Absence" else ("Period" if dataset == "Service Activity" else "Date")
                    source_period = month_from_source_value(row.get(source_period_field))
                    if source_period and source_period != period:
                        status, reason = "Review Required", "Source date period does not agree with filename period"
                    if file in duplicate_files:
                        status, reason = "Review Required", "Duplicate candidate file for this dataset and reporting month"
                    if dataset == "Workforce":
                        value = as_float(row.get("Total"))
                        if value is None or value < 0:
                            status, reason = "Rejected", "Workforce Total is missing, non-numeric or negative"
                    elif dataset == "Absence":
                        lost, available, rate = as_float(row.get("FTE_DAYS_LOST")), as_float(row.get("FTE_DAYS_AVAILABLE")), as_float(row.get("SICKNESS_ABSENCE_RATE_PERCENT"))
                        if None in {lost, available, rate} or available <= 0 or lost < 0 or not 0 <= rate <= 100:
                            status, reason = "Rejected", "Absence measure is missing, invalid or outside permitted range"
                    else:
                        attendance = sum(as_float(row.get(column)) or 0 for column in headers if column.startswith("A&E attendances"))
                        over_four = sum(as_float(row.get(column)) or 0 for column in headers if column.startswith("Attendances over 4hrs"))
                        if attendance < 0 or over_four < 0 or over_four > attendance:
                            status, reason = "Rejected", "Activity values are negative or over-four-hour attendances exceed total attendances"
                    log_record(logs, RefreshId=refresh_id, SourceFile=file.name, SourceDataset=dataset, ReportingMonth=period, RowNumber=row_number, OrganisationCode=code, RecordStatus=status, ValidationReason=reason)
                    if status == "Accepted":
                        processed.append({**row, "OrganisationCode": code, **{key: {"SourceFile": file.name, "SourceDataset": dataset, "ReportingMonth": period, "LoadTimestamp": timestamp, "RecordStatus": status, "ValidationReason": reason}[key] for key in PROVENANCE}})
    except CriticalValidationError as error:
        failure = {"RefreshId": refresh_id, "Status": "Failed", "FailedGate": "Critical input or schema validation", "Message": str(error), "Timestamp": timestamp}
        (output / "run_failure.json").write_text(json.dumps(failure, indent=2), encoding="utf-8")
        write_csv(output / "file_inventory.csv", inventory)
        write_csv(output / "refresh_log.csv", [failure])
        raise

    status_counts = Counter(row["RecordStatus"] for row in logs)
    write_csv(output / "file_inventory.csv", inventory)
    write_csv(output / "processed_data.csv", processed)
    write_csv(output / "data_quality_log.csv", logs)
    exception_rows = [row for row in logs if row["RecordStatus"] != "Accepted"]
    write_csv(output / "exception_log.csv", exception_rows)
    kpis = build_kpi_summary(processed)
    write_csv(output / "kpi_summary.csv", kpis)
    reconciliation = [{"Dataset": dataset, "RawRows": sum(1 for item in logs if item["SourceDataset"] == dataset), "AcceptedRows": sum(1 for item in logs if item["SourceDataset"] == dataset and item["RecordStatus"] == "Accepted"), "RejectedRows": sum(1 for item in logs if item["SourceDataset"] == dataset and item["RecordStatus"] == "Rejected"), "ReviewRequiredRows": sum(1 for item in logs if item["SourceDataset"] == dataset and item["RecordStatus"] == "Review Required")} for dataset in inputs]
    reconciliation, comparison_status = reconcile_previous(args.previous_refresh, reconciliation)
    write_csv(output / "reconciliation_report.csv", reconciliation)
    (output / "data_quality_log.json").write_text(json.dumps(logs, indent=2), encoding="utf-8")
    (output / "reconciliation_report.json").write_text(json.dumps(reconciliation, indent=2), encoding="utf-8")
    refresh = {"RefreshId": refresh_id, "RefreshTimestamp": timestamp, "Status": "Complete with warnings" if status_counts["Rejected"] or status_counts["Review Required"] else "Complete", "WorkforceFiles": len(inputs["Workforce"][0]), "AbsenceFiles": len(inputs["Absence"][0]), "ActivityFiles": len(inputs["Service Activity"][0]), "RawRows": len(logs), "AcceptedRows": status_counts["Accepted"], "RejectedRows": status_counts["Rejected"], "ReviewRequiredRows": status_counts["Review Required"], "Warnings": status_counts["Review Required"], "CriticalErrors": 0, "PreviousRefreshStatus": comparison_status, "OutputFolder": str(output)}
    write_csv(output / "refresh_log.csv", [refresh])
    write_commentary(output / "management_commentary.md", refresh)
    print(json.dumps(refresh, indent=2))


def build_kpi_summary(records):
    """Return only approved row-count KPIs until records are transformed to a common grain."""
    counts = Counter(record["SourceDataset"] for record in records)
    return [
        {"KPI": "Accepted workforce source rows", "Value": counts["Workforce"], "Classification": "Control measure", "ReportingGrain": "Refresh"},
        {"KPI": "Accepted absence source rows", "Value": counts["Absence"], "Classification": "Control measure", "ReportingGrain": "Refresh"},
        {"KPI": "Accepted service activity source rows", "Value": counts["Service Activity"], "Classification": "Control measure", "ReportingGrain": "Refresh"},
    ]


def write_commentary(path, refresh):
    path.write_text(
        "# Monthly management commentary\n\n"
        f"- Refresh status: {refresh['Status']}\n"
        f"- Accepted records: {refresh['AcceptedRows']:,}; review-required records: {refresh['ReviewRequiredRows']:,}; rejected records: {refresh['RejectedRows']:,}.\n"
        "- This automated draft reports data-processing status only. Review approved KPI outputs before publishing operational commentary.\n\n"
        "## Interpretation boundary\n\n"
        "The public aggregate data can show observed changes but cannot establish causality or capture rota design, staffing deployment, patient acuity, bed availability or local operational changes.\n",
        encoding="utf-8",
    )


def write_csv(path, rows):
    rows = list(rows)
    fields = sorted({field for row in rows for field in row}) if rows else ["Status"]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def parse_args():
    parser = argparse.ArgumentParser(description="Run controlled NHS monthly reporting intake and validation")
    parser.add_argument("--workforce", required=True)
    parser.add_argument("--absence", required=True)
    parser.add_argument("--activity", required=True)
    parser.add_argument("--organisation-reference", required=True)
    parser.add_argument("--kpi-dictionary", required=True)
    parser.add_argument("--previous-refresh")
    parser.add_argument("--output-dir", required=True)
    return parser.parse_args()


if __name__ == "__main__":
    try:
        run(parse_args())
    except CriticalValidationError as exc:
        print(f"CRITICAL VALIDATION FAILURE: {exc}", file=sys.stderr)
        sys.exit(2)

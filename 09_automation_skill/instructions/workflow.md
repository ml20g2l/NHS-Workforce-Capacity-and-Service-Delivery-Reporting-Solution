# Monthly reporting workflow

## 1. Input contract

| Input | Accepted format | Minimum contract | Critical failure |
|---|---|---|---|
| Workforce | CSV file or folder of CSV files | `Date`, `Org Code`, `Org Name`, `Staff Group`, `Data Type`, `Total` | Required field absent or no period found |
| Sickness absence | CSV file or folder of CSV files | `DATE`, `ORG_CODE`, `ORG_NAME`, `FTE_DAYS_LOST`, `FTE_DAYS_AVAILABLE`, `SICKNESS_ABSENCE_RATE_PERCENT` | Required field absent or no period found |
| A&E activity | CSV file or folder of CSV files | `Period`, `Org Code`, `Org name`, A&E attendance fields, over-four-hour fields, emergency-admission fields | Required field absent or no period found |
| Organisation reference | CSV | `OrganisationCode`, `CanonicalOrganisationName`, `InclusionFlag` | Missing, duplicate approved code or invalid inclusion flag |
| KPI dictionary | XLSX | Approved KPI register | Missing or unreadable |
| Previous refresh | Directory or exported controls | Previous refresh date plus KPI/reconciliation controls where comparison is required | Non-critical: continue and mark comparison unavailable |

## 2. Execution order

1. Discover input files, exclude hidden/system files and capture filenames, size and modified timestamps.
2. Derive a reporting period from the filename and, where available, compare it with the source date/period column.
3. Apply schema gate. Stop the refresh on a critical schema failure.
4. Profile rows, required-field nulls and duplicate candidate keys before transformation.
5. Standardise organisation codes: trim, uppercase and retain the original value in the quality log when changed.
6. Map codes to the organisation reference. Keep in-scope mapped records as `Accepted`; retain unmapped and out-of-scope rows as `Review Required` unless a specific validity failure requires `Rejected`.
7. Apply record-level validity checks. Classify every failed record and retain the reason.
8. Build accepted organisation-month facts only after classification. Do not join staff-group workforce rows directly to A&E rows.
9. Calculate only the approved KPIs at their documented grain.
10. Compare the current outputs to the previous refresh where a comparable prior control exists.
11. Run `build_control_workbooks.mjs` after the Python runner, using its two JSON control inputs, to create the required `data_quality_log.xlsx` and `reconciliation_report.xlsx`.
12. Produce all outputs and draft cautious management commentary.

### Execution commands

Run the validation and controlled intake first:

```powershell
python scripts/run_monthly_reporting.py --workforce <folder-or-file> --absence <folder-or-file> --activity <folder-or-file> --organisation-reference <reference.csv> --kpi-dictionary <kpi_dictionary.xlsx> --previous-refresh <optional-folder> --output-dir <timestamped-output-folder>
```

Then create the two Excel control workbooks from the produced audit data:

```powershell
node scripts/build_control_workbooks.mjs --quality-json <output-folder>/data_quality_log.json --reconciliation-json <output-folder>/reconciliation_report.json --output-dir <output-folder>
```

## 3. Output contract

| Output | Required contents |
|---|---|
| `processed_data.csv` | Accepted organisation-month records, approved measures, KPI fields and provenance columns |
| `data_quality_log.xlsx` | Rule result, severity, record status, source lineage and validation reason for every exception or classification change |
| `reconciliation_report.xlsx` | Raw, accepted, rejected and review-required rows; raw/accepted/reportable totals; current-versus-previous differences |
| `refresh_log.csv` | Refresh ID, timestamp, file counts, period range, status counts, warning/error counts and previous-refresh comparison status |
| `kpi_summary.csv` | Only KPI-dictionary measures; definition status (`Official NHS measure` or `Analytical proxy`), grain and period |
| `management_commentary.md` | Cautious observed changes, quality caveats, exceptions and follow-up questions; no causal claims |
| `exception_log_template.xlsx` output | One row per exception with owner/status fields for operational review |

## 4. Completion gate

Mark a refresh `Complete with warnings` only when all critical schema and period checks pass, all output files exist and the refresh log has a non-empty status. Mark it `Failed` when a critical gate fails. A failed refresh must still retain the file inventory and failure message.

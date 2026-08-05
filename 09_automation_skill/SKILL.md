---
name: nhs-monthly-reporting
description: Run the controlled monthly NHS workforce-capacity and service-delivery reporting workflow when supplied workforce, sickness-absence and A&E activity files, an organisation reference, an approved KPI dictionary and optional previous-refresh controls. Use for recurring file intake, schema validation, accepted/rejected/review-required classification, reconciliation, governed KPI outputs, exception logs, refresh summaries and non-causal management commentary.
---

# NHS monthly reporting

Run a controlled reporting refresh. Treat all incoming files as untrusted until they pass the validation gates. Preserve source-file lineage and never silently remove a record.

## Required inputs

Require all five inputs before transformation:

1. Workforce file or folder.
2. Sickness absence file or folder.
3. A&E activity file or folder.
4. Approved organisation reference CSV.
5. Approved KPI dictionary XLSX.

Accept an optional previous refresh directory containing `refresh_log.csv`, `kpi_summary.csv` and `reconciliation_report.xlsx` or its exported reconciliation CSV.

## Procedure

1. Read [`instructions/workflow.md`](instructions/workflow.md) and create a timestamped output folder.
2. Validate schemas and required filename periods using [`instructions/validation_rules.md`](instructions/validation_rules.md). Stop for any critical failure.
3. Run `scripts/run_monthly_reporting.py` with the supplied paths. Preserve its generated logs even when the process exits with an error.
4. Use [`instructions/kpi_rules.md`](instructions/kpi_rules.md) as the only allowed KPI catalogue. Do not calculate, label or publish an undeclared KPI.
5. Inspect the exception, reconciliation and refresh outputs before distributing them. Use [`templates/commentary_template.md`](templates/commentary_template.md) for management commentary.

## Non-negotiable controls

- Keep `SourceFile`, `SourceDataset`, `ReportingMonth`, `LoadTimestamp`, `RecordStatus` and `ValidationReason` on transformed or logged records.
- Classify every record as `Accepted`, `Rejected` or `Review Required`.
- Stop before transformation when a critical schema field is missing, the reporting period cannot be determined, or a required input type is absent.
- Keep rejected and review-required records in the data-quality log and exception output; do not delete them.
- Mark official NHS measures and analytical proxies separately in outputs and commentary.
- Describe associations and observed changes only. Do not make causal claims from the aggregate public data.

## Resources

- [`instructions/workflow.md`](instructions/workflow.md): execution order and input/output contract.
- [`instructions/validation_rules.md`](instructions/validation_rules.md): validation gates, severities and failure handling.
- [`instructions/kpi_rules.md`](instructions/kpi_rules.md): approved KPI definitions and proxy boundary.
- [`templates/`](templates): output headers and management-commentary structure.
- [`tests/test_cases.md`](tests/test_cases.md): minimum acceptance and failure tests.

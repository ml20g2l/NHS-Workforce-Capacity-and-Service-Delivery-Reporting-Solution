# Phase 7 — Recurring Reporting Simulation

## Objective

Historical monthly files are introduced sequentially to simulate a recurring
operational reporting cycle. Each cycle uses isolated generated input folders,
while the preserved NHS source files in `02_source_data/raw` remain unchanged.

The cumulative workforce extract remains in its existing staging folder.
`ReportingEndMonth` controls which workforce months are included in each cycle.

## Prerequisite

Register the 31 supplied Power Query expressions in
`03_power_query/power_query_control.xlsx`, following
`03_power_query/README.md`. Complete one successful full refresh before using
the cycle evidence as a runtime test.

## Prepare a cycle

Run one of the following from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File ".\02_source_data\prepare_reporting_cycle.ps1" -Cycle Cycle1
powershell -ExecutionPolicy Bypass -File ".\02_source_data\prepare_reporting_cycle.ps1" -Cycle Cycle2
powershell -ExecutionPolicy Bypass -File ".\02_source_data\prepare_reporting_cycle.ps1" -Cycle Cycle3
```

Generated inputs are written below `04_processed_data/reporting_cycles/` and
are excluded from Git because they are reproducible copies and controlled test
files. Each output contains:

- `cycle_manifest.csv` with file hashes and expected dispositions;
- `cycle_parameters.csv` with the six Excel parameter values;
- isolated absence and service-activity input folders;
- for Cycle 3 only, `controlled_revision_log.csv`.

Run the automated pre-refresh validation after preparing the three cycles:

```powershell
powershell -ExecutionPolicy Bypass -File ".\02_source_data\validate_reporting_cycles.ps1"
```

The script writes auditable results to:

- `05_reporting_controls/refresh_logs/phase7_pre_refresh_validation.csv`;
- `05_reporting_controls/refresh_logs/phase7_cycle_expected_inputs.csv`.

The Excel-only steps are documented in Korean in
`03_power_query/엑셀_수동_설정_가이드.md`.

## Cycle 1 — Q1 baseline

Input months: April to June 2024.

Expected checks:

1. All three months appear after refresh.
2. Workforce, absence and A&E queries respect the same reporting window.
3. Raw, accepted, review-required, rejected and reportable rows reconcile.
4. Exceptions retain source file and validation reason.
5. The Q1 report can be saved without manually restructuring queries.

## Cycle 2 — July added

Input months: April to July 2024.

Expected checks:

1. July is included automatically.
2. April to June outputs do not change.
3. Row counts increase only by explainable July records.
4. The dashboard/reporting period extends to July.
5. Refresh and reconciliation logs record the new reporting month.

## Cycle 3 — File version controls

Input months: April to July 2024, plus controlled July duplicate and revised
A&E files.

The script creates:

- an exact duplicate of the official July file;
- a revised July file with one London provider's Type 1 attendance value
  increased by one;
- explicit modified timestamps so the revised file is selected as Active.

This is a controlled pipeline test, not an observed NHS data issue or an
official correction. The original raw file is never changed.

Expected checks:

1. The revised file is the single Active July A&E file.
2. Duplicate content is classified as `Duplicate - superseded`.
3. Non-selected non-identical versions are retained and explained.
4. Only the documented one-unit change appears in the refresh comparison.
5. The file register and refresh log retain the evidence needed for audit.

## Evidence to retain after each Excel refresh

Export or copy the following query outputs into the reporting-controls folders:

- `qryPowerQueryRefreshSummary` → `05_reporting_controls/refresh_logs/`;
- `qryDataQualityReconciliation` → `05_reporting_controls/reconciliation/`;
- `qryPowerQueryExceptions` → `05_reporting_controls/exception_logs/`;
- `qrySourceFileRegister` → `05_reporting_controls/refresh_logs/`.

Do not describe a cycle as passed until the Excel Power Query refresh has
completed successfully and the output checks have been reviewed.

## Preparation verification

Static preparation was verified on 24 July 2026:

| Check | Result |
|---|---:|
| Power Query package validator | PASS |
| M queries present | 31 |
| Phase 7 pre-refresh controls | 29/29 PASS |
| Cycle 1 manifest rows / months | 6 / 3 |
| Cycle 2 manifest rows / months | 8 / 4 |
| Cycle 3 manifest rows / months | 10 / 4 |
| Cycle 3 controlled duplicate versions | 2 |
| Original July A&E raw-file hash unchanged | PASS |
| Controlled revised file | RAN, Type 1 attendances, 0 → 1 |

These results confirm that the simulation inputs are reproducible and that the
raw source boundary is preserved. They do not replace the required Excel
Power Query runtime refresh.

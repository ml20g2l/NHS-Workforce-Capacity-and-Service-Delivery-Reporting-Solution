# NHS Workforce Capacity & Service Delivery Reporting

This portfolio project simulates a recurring monthly operational reporting process using public NHS workforce, sickness absence and A&E activity data.

Each reporting period is treated as a new operational input. Incoming files are validated, reconciled against previous submissions, transformed into governed KPI outputs and prepared for Excel and Power BI reporting for non-technical operational managers.

## Current Status

- Phase 1 project brief completed.
- Phase 2 official source files and source register completed for April 2024 to March 2025.
- Phase 3 KPI dictionary completed using confirmed source fields.
- Phase 4 star-schema design completed, including a safe organisation-month summary grain.
- Phase 5 Power Query package completed with 31 ordered M queries, file-version selection and row-level provenance.
- Phase 6 data-quality framework completed with a 42-rule matrix, exception outputs and reconciliation controls.
- A controlled 148-organisation stable reference has been created; the reporting cohort is the 20 London providers present in all three sources for all 12 months.
- Power Query connections still require one-time manual registration in Excel Advanced Editor, followed by an actual refresh and result verification.

## Phase 7 Readiness

Historical monthly files will be introduced sequentially to simulate a recurring reporting cycle. Before the simulation begins, install and refresh the M queries using `03_power_query/power_query_control.xlsx` and the instructions in `03_power_query/README.md`.

The readiness review is documented in `10_documentation/phase_1_to_6_readiness_review.md`.

## Repository Structure

```text
01_project_brief/
02_source_data/
  raw/
  reference/
03_power_query/
  m/
04_processed_data/
05_reporting_controls/
  data_quality/
  reconciliation/
  exception_logs/
  refresh_logs/
  kpi_dictionary/
06_excel_reporting/
07_power_bi/
08_ad_hoc_analysis/
09_automation_skill/
10_documentation/
README.md
```

## Data Boundary

The project uses public, aggregate NHS statistics only. It does not involve internal NHS systems, patient-level data or employee-level data.

See [the project brief](01_project_brief/project_brief.md) for scope, users, business questions, controls, KPIs, limitations and success criteria.

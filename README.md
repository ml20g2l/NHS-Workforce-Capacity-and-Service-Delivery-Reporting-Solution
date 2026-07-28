# NHS Workforce Capacity & Service Delivery Reporting

This portfolio project simulates a recurring monthly operational reporting process using public NHS workforce, sickness absence and A&E activity data.

Each reporting period is treated as a new operational input. Incoming files are validated, reconciled against previous submissions, transformed into governed KPI outputs and prepared for Excel and Power BI reporting for non-technical operational managers.

## Current Status

- Phase 1 project brief completed.
- Phase 2 official source files and source register completed for April 2024 to March 2025.
- Phase 3 KPI dictionary completed using confirmed source fields.
- Phase 4 star-schema design completed, including a safe organisation-month summary grain.
- Phase 5 Power Query package completed with 40 ordered M queries, file-version selection, row-level provenance and a model-ready reporting layer.
- Phase 6 data-quality framework completed with a 42-rule matrix, exception outputs and reconciliation controls.
- Phase 7 recurring reporting simulation completed for the Q1 baseline, July extension and controlled duplicate/revised-file scenario.
- The full-year Excel reporting workbook now includes refreshed outputs, active Data Model relationships and three manager-facing PivotTable views.
- A controlled 148-organisation stable reference has been created; the reporting cohort is the 20 London providers present in all three sources for all 12 months.

## Phase 7 Reporting-Cycle Simulation

Historical monthly files were introduced sequentially through three
reproducible cycle inputs: an April–June baseline, July addition, and a
controlled duplicate/revised-file test. The completed simulation and
validation evidence are documented in
`10_documentation/reporting_cycle_simulation.md`.

The final Excel deliverable is
`03_power_query/power_query_control_full_year_baseline.xlsx`. It contains the
full April 2024 to March 2025 reporting period, refreshed Power Query outputs,
the star-schema Data Model and manager-facing PivotTables. Query definitions,
load roles and relationships are documented in `03_power_query/README.md`.

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

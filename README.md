# NHS Workforce Capacity & Service Delivery Reporting

This portfolio project simulates a recurring monthly operational reporting process using public NHS workforce, sickness absence and A&E activity data.

Each reporting period is treated as a new operational input. Incoming files will be validated, reconciled against previous submissions, transformed into governed KPI outputs and published through Excel and Power BI reporting for non-technical operational managers.

## Current Status

- Project structure scaffolded.
- Initial project brief completed.
- Source data has not yet been downloaded.
- Reporting pipeline and outputs have not yet been built.

## Repository Structure

```text
NHS-Workforce-Capacity-and-Service-Delivery-Reporting/
├── 01_project_brief/
│   └── project_brief.md
├── 02_source_data/
├── 03_power_query/
├── 04_processed_data/
├── 05_reporting_controls/
│   ├── data_quality/
│   ├── reconciliation/
│   ├── exception_logs/
│   ├── refresh_logs/
│   └── kpi_dictionary/
├── 06_excel_reporting/
│   ├── pivot_tables/
│   └── manager_pack/
├── 07_power_bi/
├── 08_ad_hoc_analysis/
├── 09_automation_skill/
├── 10_documentation/
│   ├── reporting_calendar/
│   ├── workflow/
│   └── user_guide/
└── README.md
```

## Data Boundary

The project will use public, aggregate NHS statistics only. It does not involve internal NHS systems, patient-level data or employee-level data.

See [the project brief](01_project_brief/project_brief.md) for scope, users, business questions, controls, KPIs, limitations and success criteria.

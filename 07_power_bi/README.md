# Power BI Self-Service Dashboard

## Status

Phase 9 is complete. The dashboard translates the controlled reporting model into a self-service experience for operational managers.

Open [`NHS_Workforce_Capacity_Service_Delivery.pbix`](NHS_Workforce_Capacity_Service_Delivery.pbix) in Power BI Desktop.

## Included assets

- `NHS_Workforce_Capacity_Service_Delivery.pbix` — completed Power BI report.
- `config/kpi_targets.csv` — governed KPI target and source evidence.
- `config/alert_rules.csv` — configurable operational alert rules.
- `dax/core_measures.dax` — core weighted, latest-period, change and control measures.
- `power_bi_model_load_plan.md` — model tables, load roles and relationship notes.
- `theme/nhs_operations_theme.json` — report theme.

## Report pages

1. **Executive Overview** — monthly operational performance, capacity and demand trends, four-hour performance against the configured reference, and high-priority management alerts.
2. **Workforce & Availability** — workforce composition, headcount, absence rate, estimated capacity loss and provider absence watchlist.
3. **Demand & Delivery** — A&E demand, admissions, long waits, lowest four-hour performance and delivery watchlist.
4. **Capacity Pressure** — demand-to-available-capacity proxy, demand versus capacity movement, and provider pressure comparison.
5. **Data Quality & Refresh** — record status, active reporting files, reconciliation totals and exception summary.
6. **Organisation Detail** *(hidden)* — drill-through view retaining the selected organisation and reporting month.

## Use

Use the reporting-month, location, organisation-type and organisation slicers to focus the visible report pages. The **Reset filters** button restores the published view. Select an organisation in an organisation-level visual and use drill-through to open the Organisation Detail page.

## Metric governance and controls

The 2024/25 four-hour A&E objective is stored as a configuration record rather than hard-coded into visuals. The March 2025 reference is 78% seen within four hours.

Capacity-pressure thresholds are controlled analytical rules, not official NHS clinical or performance standards. The Data Quality & Refresh page distinguishes reportable rows from rows retained for review, traceability and audit.

## Source boundary

The dashboard uses public aggregate NHS data only. Estimated available FTE, attendances per available FTE and risk flags are analytical proxies; they are not patient-level, roster-level or clinical productivity measures.

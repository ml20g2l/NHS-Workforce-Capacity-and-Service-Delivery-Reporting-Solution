# NHS Workforce Capacity & Service Delivery Reporting

This portfolio project simulates a repeatable monthly operational reporting process using public NHS workforce, sickness absence and A&E activity data.

Rather than analysing a one-off historical dataset, each reporting period is treated as a new operational input. Files are validated, reconciled against prior submissions, transformed into governed KPI outputs and published for non-technical operational managers through Excel and Power BI.

## Reporting scope

- **Reporting period:** April 2024 to March 2025
- **Cohort:** 20 London providers consistently represented across the three source areas
- **Sources:** NHS Workforce Statistics, NHS Sickness Absence Rates, and A&E Attendances and Emergency Admissions
- **Grain for cross-source comparison:** reporting month × organisation

## Delivered solution

- A documented project brief, source register, KPI dictionary and star-schema design.
- A Power Query pipeline with file-version selection, source provenance, record classification, exception outputs and reconciliation controls.
- A recurring-reporting simulation covering a baseline load, a new-period addition and a controlled duplicate/revised-file scenario.
- An Excel reporting workbook with refreshed outputs, active Data Model relationships and manager-facing PivotTable views.
- A Power BI self-service dashboard with six KPI-led reporting experiences, including a hidden organisation drill-through page.
- A reproducible ad hoc investigation into deteriorating four-hour performance despite broadly stable workforce FTE.

## Power BI dashboard

Open [`07_power_bi/NHS_Workforce_Capacity_Service_Delivery.pbix`](07_power_bi/NHS_Workforce_Capacity_Service_Delivery.pbix) to view the completed dashboard.

Visible pages:

1. **Executive Overview** — workforce, availability, demand, delivery performance and management alerts.
2. **Workforce & Availability** — FTE, headcount, sickness absence, staff-group mix and an organisation absence watchlist.
3. **Demand & Delivery** — attendances, admissions, four-hour performance, long waits and a delivery watchlist.
4. **Capacity Pressure** — demand-to-capacity proxy, month-on-month movement and provider comparison.
5. **Data Quality & Refresh** — record status, active source files, reconciliation totals and exception visibility.

The hidden **Organisation Detail** page supports drill-through from organisation-level visuals and retains the reporting-month selection. Each visible page includes clear slicers and a reset-filter control.

## Reporting controls

Historical monthly files were introduced sequentially through three reproducible cycle inputs: an April–June baseline, a July addition, and a controlled duplicate/revised-file test. The completed evidence is documented in [`10_documentation/reporting_cycle_simulation.md`](10_documentation/reporting_cycle_simulation.md).

The final Excel delivery is [`03_power_query/power_query_control_full_year_baseline.xlsx`](03_power_query/power_query_control_full_year_baseline.xlsx). Power Query definitions, load roles and relationships are documented in [`03_power_query/README.md`](03_power_query/README.md). Power BI model notes, DAX measures, controls and the dashboard theme are in [`07_power_bi`](07_power_bi).

## Ad hoc investigation

The Phase 10 investigation screens the London cohort for providers with broadly stable workforce FTE and a material deterioration in four-hour performance. It separates observed patterns from causal claims and documents the operational evidence required for follow-up. See [`08_ad_hoc_analysis/four_hour_performance_investigation.md`](08_ad_hoc_analysis/four_hour_performance_investigation.md).

## Repository structure

```text
01_project_brief/
02_source_data/
03_power_query/
04_processed_data/
05_reporting_controls/
06_excel_reporting/
07_power_bi/
08_ad_hoc_analysis/
09_automation_skill/
10_documentation/
```

## Data boundary and limitations

This project uses public aggregate NHS statistics only. It does not use internal NHS systems, patient-level data or employee-level data.

Estimated available FTE, attendances per available FTE, capacity-pressure indicators and risk flags are analytical proxies. They support operational discussion but must not be interpreted as causal findings, roster-level capacity measures, clinical productivity measures or performance standards.

See [the project brief](01_project_brief/project_brief.md) for business context, reporting users, KPI governance, scope, limitations and success criteria.

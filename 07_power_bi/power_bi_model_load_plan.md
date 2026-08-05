# Power BI Model Load Plan

## Purpose

This plan defines the minimum model preparation required before building the
five visible dashboard pages and the organisation drill-through page.

Power BI must reuse the controlled Power Query pipeline. PivotTable worksheets
and visually formatted Excel report ranges are presentation outputs and must not
be imported as fact tables.

## Parameters

Create Power Query parameters for:

| Parameter | Value |
|---|---|
| `WorkforceFolder` | Controlled workforce source folder |
| `AbsenceFolder` | Controlled absence source folder |
| `ActivityFolder` | Controlled A&E source folder |
| `ReferenceFolder` | `02_source_data/reference` |
| `ReportingStartMonth` | `2024-04-01` |
| `ReportingEndMonth` | `2025-03-01` |

Use environment-independent parameters before publishing. Do not leave a
personal OneDrive path embedded in the published report.

## Query load settings

### Load to the model

| Power Query output | Power BI table name | Purpose |
|---|---|---|
| `DimDate` | `DimDate` | Monthly reporting calendar |
| `dimOrganisation` | `DimOrganisation` | Controlled provider dimension |
| `dimStaffGroup` | `DimStaffGroup` | Workforce staff-group dimension |
| `factWorkforceReporting` | `FactWorkforceReporting` | Additive top-level staff mix |
| `FactAbsence` | `FactAbsence` | Organisation-month absence measures |
| `FactServiceActivity` | `FactServiceActivity` | Organisation-month A&E measures |
| `FactOrganisationMonthlyPerformance` | `FactOrganisationMonthlyPerformance` | Safe cross-source summary |
| `qryPowerQueryExceptions` | `Exceptions` | Current non-accepted records |
| `qryPowerQueryRefreshSummary` | `RefreshSummary` | Current refresh and row status |
| `qrySourceFileRegister` | `SourceFileRegister` | Version and duplicate-file control |
| `dqRuleResults` | `DataQualityRuleResults` | Accepted, review and rejected counts |
| `dqReconciliation` | `Reconciliation` | Raw-to-accepted-to-reportable control |
| `config/kpi_targets.csv` | `KPI_Targets` | Disconnected KPI target table |
| `config/alert_rules.csv` | `AlertRules` | Disconnected alert governance table |

### Connection only

- Parameters and transformation functions
- Source-folder queries
- Staging queries
- Classified source queries
- `FactWorkforce`
- `wrkWorkforceOrgMonth`
- `wrkAbsenceOrgMonth`
- `wrkServiceOrgMonth`

`FactWorkforce` is retained as an auditable detailed transformation output.
The dashboard uses `FactWorkforceReporting`, which contains only the four
non-overlapping top-level groups required for additive staff-mix reporting.

## Relationships

Create active, single-direction, one-to-many relationships:

- `DimDate[MonthKey]` to every loaded fact table's `MonthKey`
- `DimOrganisation[OrganisationCode]` to every loaded fact table's
  `OrganisationKey`
- `DimStaffGroup[StaffGroupKey]` to
  `FactWorkforceReporting[StaffGroupKey]`

Do not create fact-to-fact relationships.

The configuration and control tables remain disconnected unless a dedicated
control dimension is added later.

## Measure rules

1. Executive cards show the latest month in the current filter context, not a
   twelve-month sum.
2. Sickness absence is weighted as FTE days lost divided by FTE days available.
3. Four-hour performance is weighted as attendances within four hours divided
   by total attendances.
4. Staff mix uses `FactWorkforceReporting`; organisation headline totals use
   `FactOrganisationMonthlyPerformance`.
5. Estimated available FTE and capacity-pressure metrics remain labelled as
   analytical proxies.
6. The 78% value is the official March 2025 period-end objective. It is used as
   a dashboard reference benchmark and must not be described as a separately
   published monthly provider target.

## Pre-build acceptance checks

- `DimDate[MonthKey]` contains 12 unique months.
- `DimOrganisation[OrganisationCode]` is unique.
- `FactOrganisationMonthlyPerformance` is unique at month and organisation.
- `FactWorkforceReporting` contains only staff-group sort orders 2, 19, 23 and
  28.
- Provider attendance totals reconcile to the approved Excel report.
- Weighted ratio measures reconcile to source numerators and denominators.
- Every reportable fact key matches its dimension.
- Latest refresh timestamp is populated.
- Revised and superseded files remain visible in `SourceFileRegister`.
- The 12 published A&E aggregate `TOTAL` rows reconcile to
  `Expected Controlled Exclusions` and do not trigger the unexpected-rejection
  alert.
- No personal folder path remains in the publishable parameter set.

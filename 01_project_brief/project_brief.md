# NHS Workforce Capacity & Service Delivery Reporting Solution

## Project Brief

| Document field | Detail |
|---|---|
| Project type | Junior Reporting Analyst portfolio project |
| Reporting cycle | Monthly, with weekly-style management views where the source permits |
| Primary tools | Excel, Power Query, PivotTables and Power BI |
| Data classification | Public, aggregate NHS statistics only |
| Initial analysis window | A rolling 12-month period |
| Initial organisational scope | One NHS England region and approximately 10–20 provider organisations, subject to consistent coverage across sources |
| Document status | Initial project brief |

## 1. Executive Summary

This project will design a repeatable operational reporting solution that combines public NHS workforce, sickness absence and A&E activity statistics. Rather than treating the source files as a one-off historical dataset, each reporting month will be handled as a new operational input. The solution will validate incoming files, standardise organisational and staff-group fields, reconcile the current refresh with previously processed data, calculate governed KPIs and publish management-ready outputs in Excel and Power BI.

The project is designed to demonstrate the responsibilities of a Junior Reporting Analyst supporting recurring workforce-capacity and service-delivery reporting. It will place particular emphasis on data quality, transparent reconciliation, consistent KPI definitions, exception management and self-service reporting for non-technical users.

This is a portfolio simulation based exclusively on publicly available, aggregate statistics. It does not represent work commissioned by NHS England or an NHS provider, and it will not claim access to internal NHS systems, operational rosters, payroll records or patient-level data.

## 2. Business Scenario

A regional operations team reviews the workforce capacity and service delivery of multiple NHS provider organisations each month. Workforce, sickness absence and A&E activity data are published separately, use different structures and may be released on different schedules. Organisation names or classifications can change, reporting periods may not align perfectly and revised files may be published after an earlier version has already been used.

The current simulated process has several operational weaknesses:

- Analysts manually copy data from separate spreadsheets into recurring reports.
- Organisation and staff-group labels are not consistently standardised across sources.
- Duplicate records, missing identifiers and unmapped organisations are difficult to detect.
- KPI definitions can vary between workbooks or reporting periods.
- Managers repeatedly ask analysts for the same provider-level and staff-group-level breakdowns.
- Changes caused by revised or incomplete data can be mistaken for genuine performance changes.
- Workforce pressure, sickness absence, demand and service performance cannot be compared in one controlled reporting view.

The proposed solution will replace this fragmented process with a governed monthly refresh that preserves source evidence, records data-quality exceptions, reconciles changes and produces consistent management information.

## 3. Project Objective

Build a reproducible monthly reporting solution that integrates workforce, sickness absence and A&E activity data; validates and reconciles each refresh; applies controlled KPI definitions; and enables operational managers to investigate capacity and delivery performance without rebuilding the analysis manually.

The solution should help users distinguish among:

- a genuine change in workforce capacity;
- an increase in sickness-related capacity loss;
- higher service demand;
- weaker service delivery;
- a data-quality, coverage, timing or revision issue.

## 4. Reporting Users

| User group | Reporting need | Intended output |
|---|---|---|
| Regional operations managers | Identify providers under the greatest workforce or service pressure | Power BI management dashboard and exception-led summary |
| Workforce and capacity managers | Review workforce size, staff mix, absence and estimated available capacity | Excel PivotTables and Power BI workforce views |
| Service delivery managers | Compare demand, four-hour performance and long waits across providers and months | Power BI service-delivery views |
| Reporting analysts | Refresh, validate, reconcile and explain changes | Power Query pipeline, control files and refresh log |
| Senior management | Receive a concise summary of material movements, risks and required follow-up | Excel manager pack and management commentary draft |

The primary audience is non-technical management. Outputs must therefore use clear labels, documented definitions, visible reporting periods and simple navigation while retaining drill-down capability for analysts.

## 5. Business Questions

The reporting solution will address the following recurring questions:

1. How has workforce FTE and headcount changed by provider, staff group and month?
2. Which organisations or staff groups have the highest sickness absence rates and FTE days lost?
3. How does estimated available workforce capacity change after adjusting reported FTE by the published sickness absence rate?
4. Which providers are experiencing the highest A&E demand relative to estimated available FTE?
5. How are total attendances, emergency admissions, four-hour performance and long waits changing over time?
6. Where do falling workforce levels, rising absence and increasing demand occur together?
7. Which provider movements are material relative to the previous reporting month?
8. Are apparent changes caused by operational performance, missing data, inconsistent mappings, late publication or revised source files?
9. Which exceptions require investigation before management reporting is released?
10. Can managers answer routine provider and staff-group questions through filters and drill-downs without requesting a new analyst-built report?

The project may also support focused ad hoc investigations, such as: “Why did service pressure increase for a selected provider?” Any answer will separate evidence from hypothesis and will not infer causality from aggregate observational data.

## 6. Scope

### 6.1 In Scope

- A rolling 12-month reporting period for the initial release.
- One NHS England region and approximately 10–20 provider organisations with sufficient coverage across the three sources.
- Four to six major staff groups, selected after source profiling.
- Monthly public data ingestion from NHS Workforce Statistics, NHS Sickness Absence Rates and A&E Attendances and Emergency Admissions.
- A controlled organisation reference table based primarily on organisation codes.
- Standardisation of reporting periods, organisation identifiers, organisation names, organisation types, region labels and staff groups where available.
- Duplicate, completeness, validity, consistency, timeliness and mapping checks.
- Separation of accepted, warning and rejected records using documented rules.
- Reconciliation of the current refresh against the previous processed version.
- KPI calculation through documented and version-controlled definitions.
- Excel-based refresh, control and PivotTable outputs for operational use.
- A Power BI dashboard designed for non-technical management users.
- One documented ad hoc investigation demonstrating root-cause classification.
- A reusable automation skill or workflow specification that can inspect a new file set and produce validation, exception, KPI, refresh-log and commentary outputs.

### 6.2 Out of Scope

- Patient-level, employee-level, payroll, rota, clinical or personally identifiable data.
- Direct access to NHS internal systems, databases or APIs requiring restricted credentials.
- Clinical effectiveness, patient safety or individual treatment-outcome analysis.
- Forecasting staff requirements or prescribing operational staffing decisions in the first release.
- Causal claims about the relationship between workforce, absence and A&E performance.
- Replacement of official NHS publications or locally governed management information.
- Real-time reporting; the solution follows the publication cadence and latency of the public sources.
- Organisation-level target setting where a reliable, comparable target is not available.

## 7. Data Sources

Only official, public and aggregate NHS publications will be used. The exact files, URLs, download dates and version identifiers will be recorded in a source register during implementation.

### 7.1 NHS Workforce Statistics

**Purpose:** Measure workforce capacity and staff-group composition.

**Expected fields:**

- reporting month;
- organisation code and name;
- region and organisation type;
- staff group or occupation group;
- headcount;
- full-time equivalent (FTE).

**Planned uses:**

- total FTE and headcount;
- FTE per head;
- month-on-month and year-on-year workforce change;
- workforce mix by staff group;
- provider-level capacity trends.

The publication reports monthly Hospital and Community Health Services workforce data, including FTE and headcount. Final field selection will follow profiling of the chosen downloadable files.

### 7.2 NHS Sickness Absence Rates

**Purpose:** Measure sickness-related capacity loss and provide an availability adjustment.

**Expected fields:**

- reporting month;
- organisation code and name;
- region and organisation type;
- staff group;
- FTE days available;
- FTE days lost;
- sickness absence rate.

**Planned uses:**

- absence rate;
- FTE days lost;
- month-on-month absence change;
- staff-group and provider absence pressure;
- estimated available FTE as a capacity proxy.

The publication provides monthly absence information at several aggregate levels. Joins will use the most compatible provider and staff-group grain available, and aggregate levels will not be mixed without explicit controls.

### 7.3 A&E Attendances and Emergency Admissions

**Purpose:** Measure urgent and emergency care demand and service delivery.

**Expected fields:**

- reporting month;
- provider organisation code and name;
- A&E type;
- total attendances;
- emergency admissions;
- attendances within four hours or the corresponding performance fields;
- attendances over four hours;
- waits following a decision to admit, where consistently available.

**Planned uses:**

- total A&E attendances;
- emergency admissions as a percentage of attendances;
- four-hour performance;
- long-wait rate;
- demand growth;
- attendances per estimated available FTE;
- a transparent service-pressure view.

The official monthly aggregate collection will be used rather than patient-level Emergency Care Data Set records. Provider coverage, A&E type and revisions will be checked before comparisons are made.

### 7.4 Reference Data

A controlled reference table will hold:

- canonical organisation code and name;
- region;
- organisation type;
- valid-from and valid-to dates where relevant;
- alternative names encountered in source files;
- inclusion flag;
- mapping status and review notes.

Organisation code will be the preferred join key. Name-based matching will be used only as a controlled exception and will require review before acceptance.

## 8. Data Model and Integration Principles

Each source will retain its natural grain in a curated fact table. Conformed dimensions will include reporting month, organisation and, where compatible, staff group. Published measures will not be duplicated across incompatible aggregate levels.

The first integration release will follow these principles:

- preserve the original source file unchanged;
- add source file name, import timestamp and refresh identifier to processed records;
- use a month-end reporting key consistently;
- join primarily on organisation code and reporting month;
- aggregate before joining when source grains differ;
- document all exclusions and mapping decisions;
- avoid many-to-many joins;
- reconcile totals before and after every transformation stage.

## 9. KPI Framework

Initial KPIs are provisional until source profiling confirms field availability and grain.

| KPI | Working definition | Use and caution |
|---|---|---|
| Total FTE | Sum of valid published workforce FTE at the selected grain | Core workforce capacity measure |
| Headcount | Sum of valid published headcount at the selected grain | Must not be added across overlapping staff hierarchies |
| FTE per head | Total FTE / headcount | Indicates average contracted FTE, not productivity |
| Workforce change | (Current FTE − comparison FTE) / comparison FTE | Comparison period must be visible |
| Sickness absence rate | Published FTE days lost / published FTE days available, or the official published rate | Published definition takes precedence |
| Estimated available FTE | Workforce FTE × (1 − sickness absence rate) | Capacity proxy only; not an actual staffed-shift measure |
| Total A&E attendances | Sum of valid attendances for included A&E types | Coverage and A&E type must be consistent |
| Attendances per estimated available FTE | Total attendances / estimated available FTE | Contextual pressure indicator, not a productivity target |
| Emergency admission rate | Emergency admissions / total attendances | Subject to published collection definitions |
| Four-hour performance | Attendances meeting the four-hour measure / eligible attendances | Denominator and collection definition must be documented |
| Long-wait rate | Relevant long-wait count / documented eligible denominator | Implement only where a consistent denominator exists |
| Data quality score | Weighted result across completeness, validity, consistency, uniqueness and timeliness | Component weights and thresholds must be transparent |

A composite “service pressure index” will not be published until its components, weighting and interpretation have been reviewed. The first release will favour a clear set of separate indicators over an opaque score.

## 10. KPI Governance

A KPI dictionary will be maintained as a controlled reporting artifact. Every published KPI must include:

- KPI name and business purpose;
- plain-language definition;
- formula and aggregation rule;
- numerator and denominator;
- unit and formatting;
- source dataset and source fields;
- required dimensions and valid grain;
- filters and exclusions;
- comparison period;
- refresh frequency;
- data owner or simulated business owner;
- reporting owner;
- target source, where applicable;
- known caveats;
- version, approval status and effective date;
- worked example and test case.

Governance rules:

1. One approved definition will be reused across Excel, Power BI and commentary outputs.
2. Calculations will be centralised where practical rather than recreated independently in each visual.
3. New or changed definitions will be documented in a KPI change log and tested before publication.
4. A KPI without a validated denominator, comparable grain or documented source will not be presented as final.
5. Missing targets will be shown as “Not available” rather than replaced with invented values.
6. Proxy measures, including estimated available FTE, will be clearly labelled as proxies.
7. Dashboard tooltips and the user guide will expose definitions and limitations to end users.

## 11. Reporting Controls

### 11.1 Data Quality Controls

The refresh will test for:

- duplicate rows at the expected business key;
- missing reporting month, organisation code or required measure;
- unmatched or inactive organisation mappings;
- invalid data types and negative values where not permitted;
- impossible rates, such as percentages outside valid bounds;
- inconsistent organisation names for the same code;
- unexpected staff groups or A&E types;
- missing target values where a target is expected;
- incomplete provider coverage;
- late or missing source files;
- unexpected schema or column changes;
- material outliers relative to recent periods.

Checks will produce record counts, affected values, severity and disposition. Warnings may remain in accepted data when their impact is understood and documented; errors that prevent reliable use will be excluded pending resolution.

### 11.2 Reconciliation Controls

Each refresh will reconcile:

- raw rows received;
- accepted rows;
- warning rows;
- rejected or excluded rows;
- duplicate rows removed;
- totals before and after transformation;
- workforce FTE and headcount;
- FTE days available and lost;
- A&E activity totals;
- current results against the previous refresh for overlapping periods;
- revised source values against previously stored source values.

Every difference must be attributable to a documented transformation, scope rule, correction, revision or unresolved exception.

### 11.3 Exception Log

The exception log will include:

- exception identifier;
- refresh identifier and reporting month;
- source file;
- affected organisation or staff group;
- issue category;
- description and evidence;
- severity;
- data/performance classification;
- owner;
- status;
- action and resolution;
- opened and closed dates;
- reporting impact.

### 11.4 Refresh and Change Logs

The refresh log will capture refresh date and time, reporting period, files loaded, file versions, row counts, accepted and rejected records, warnings, refresh duration, output status and analyst sign-off.

The change log will summarise material differences from the prior refresh, including new or removed providers, revised historical values, mapping changes, KPI-definition changes and significant month-on-month movements.

### 11.5 Root-Cause Classification

Investigations will first classify an issue as one or more of:

- data availability or late publication;
- data quality or mapping;
- source revision;
- workforce change;
- sickness absence change;
- demand change;
- service delivery change;
- other or unresolved.

This prevents a data issue from being reported prematurely as a performance issue.

## 12. Expected Outputs

1. **Excel and Power Query reporting pipeline**  
   A folder-based ingestion process that combines monthly files, standardises fields, applies validation rules and creates refreshable curated tables.

2. **Data quality report**  
   A summary of completeness, validity, consistency, uniqueness and timeliness checks, including a transparent data-quality score.

3. **Reconciliation workbook**  
   A controlled view of raw, accepted, warning and excluded rows; key measure totals; and changes from the previous refresh.

4. **Exception, refresh and change logs**  
   Auditable operational records of issues, refresh activity, revisions and material changes.

5. **KPI dictionary**  
   A single source of truth for the definitions used across all outputs.

6. **Excel PivotTable weekly-style report and manager pack**  
   Refreshable provider, staff-group and trend views that non-technical users can filter directly in Excel. Although the underlying sources are monthly, layouts may follow a familiar weekly management-pack style without implying weekly data granularity.

7. **Power BI management dashboard**  
   Self-service views covering workforce capacity, absence, demand, service delivery, target variance where valid, data quality and exceptions.

8. **Ad hoc investigation**  
   A documented investigation into a material provider movement, separating data issues from plausible operational drivers.

9. **Automation skill or reproducible workflow**  
   A reusable process that inspects a new monthly file set and generates a validation summary, exception file, KPI output, refresh log and draft management commentary.

10. **Documentation**  
    A reporting calendar, workflow diagram, data dictionary, methodology, user guide and refresh instructions.

## 13. Recurring Monthly Reporting Workflow

| Stage | Activity | Control evidence | Output |
|---|---|---|---|
| 1. Receive | Download the latest official files and capture source URLs, publication dates and file versions | Source register and file naming check | Archived raw inputs |
| 2. Intake validation | Confirm expected files, periods, schemas and basic row counts | Intake checklist | Pass/fail status |
| 3. Transform | Refresh Power Query, standardise fields and apply reference mappings | Transformation steps and mapping table | Staged tables |
| 4. Validate | Run duplicate, completeness, validity, consistency, timeliness and coverage checks | Data quality report | Accepted, warning and rejected records |
| 5. Reconcile | Compare raw to processed totals and the current refresh to the prior refresh | Reconciliation workbook | Explained variances |
| 6. Review exceptions | Assign severity, owner, status and reporting impact | Exception log | Approved actions |
| 7. Calculate KPIs | Apply approved KPI definitions at valid grains | KPI dictionary and tests | Governed KPI tables |
| 8. Quality assurance | Review material movements, filters, totals and dashboard behaviour | QA checklist | Analyst sign-off |
| 9. Publish | Refresh Excel outputs and Power BI; update visible reporting period | Publication checklist | Management outputs |
| 10. Communicate | Produce a concise summary of changes, risks and required follow-up | Change log and commentary review | Management commentary |
| 11. Archive | Store inputs, processed outputs, logs and version details | Archive checklist | Reproducible refresh record |

A simulated reporting calendar will assign these stages to working days based on the actual release timing of each source. If sources for the same reporting month become available at different times, the reporting status will clearly distinguish provisional, partial and complete refreshes.

## 14. Dashboard and Self-Service Principles

The management dashboard will:

- show the latest complete reporting period prominently;
- allow filtering by organisation, region, organisation type, staff group and month where available;
- present workforce, absence, demand and delivery measures in a logical sequence;
- display data-quality warnings and refresh status near affected views;
- use consistent KPI names, units, colours and comparison periods;
- provide definitions through tooltips or a dedicated information page;
- support drill-through from summary results to provider detail;
- avoid unsupported rankings or red/amber/green status where no governed threshold exists;
- include a reset-filters option and a short user guide.

## 15. Limitations and Assumptions

- Public aggregate data cannot reproduce local operational rosters, skill mix by shift, vacancies, agency staffing, overtime, productivity or true available hours.
- Estimated available FTE is a derived capacity proxy. It does not measure the number of staff present for a particular service or shift.
- Workforce, absence and A&E datasets may have different publication lags, coverage, organisational structures and aggregation levels.
- Staff-group detail may not align directly with provider-level A&E activity; some comparisons will therefore be made only at a higher compatible grain.
- A&E demand cannot be attributed solely to workforce capacity, and observed associations will not establish causality.
- Organisation mergers, code changes, boundary changes and reclassifications may affect time-series comparability.
- Published files can be revised. The workflow will detect and record revisions but cannot independently validate every source submission.
- The chosen region and providers may not be representative of England as a whole.
- Small denominators and missing providers may distort rates or comparisons.
- “Target variance” will be produced only where an authoritative and consistently applicable target and denominator can be documented.
- The portfolio project will simulate ownership, approval and escalation roles; it will not imply that actual NHS managers participated.

## 16. Success Criteria

The project will be considered successful when:

1. A new monthly file set can be added and refreshed without manually copying source rows into the reporting model.
2. All imported records retain source file, reporting period and refresh lineage.
3. Required-field, duplicate, validity, mapping, coverage and timeliness checks run consistently for every refresh.
4. Raw, accepted, warning and rejected row counts reconcile, and key measure totals can be traced through the pipeline.
5. Changes to previously reported periods are detected and recorded as revisions.
6. Every published KPI has one documented definition that is applied consistently in Excel and Power BI.
7. The solution prevents or flags invalid joins, double counting and incompatible aggregation.
8. A non-technical user can filter to a provider, month and relevant staff group and answer common management questions without rebuilding the report.
9. The latest reporting period, refresh status, data-quality status and known limitations are visible to users.
10. At least one ad hoc investigation demonstrates a structured distinction between data issues and plausible performance drivers.
11. Another analyst can follow the documentation to reproduce the refresh and understand all material exclusions.
12. Management commentary is generated from reconciled outputs and reviewed before publication.

## 17. Delivery Approach

The project will be delivered incrementally:

1. confirm source files, scope and compatible grains;
2. profile the data and build reference mappings;
3. define the KPI dictionary and validation rules;
4. build and test the Power Query pipeline;
5. implement reporting controls and reconciliation;
6. develop Excel PivotTables and the manager pack;
7. develop and test the Power BI dashboard;
8. complete an ad hoc investigation;
9. document and package the recurring refresh workflow;
10. review the solution against the success criteria.

## 18. Portfolio Positioning

The project demonstrates reporting-process design rather than one-off analysis:

> This project simulates a recurring monthly operational reporting process using public historical data. Each reporting period is treated as a new operational input. Incoming files are validated, reconciled against previous submissions, transformed into consistent KPI outputs and published through Excel and Power BI reporting that operational managers can use without rebuilding the analysis manually.

It is intended to demonstrate transferable capability in workforce reporting, operational performance, capacity analysis, data quality, KPI governance, reconciliation and self-service management information.

## 19. Official Source References

- [NHS Workforce Statistics](https://digital.nhs.uk/data-and-information/publications/statistical/nhs-workforce-statistics)
- [NHS Sickness Absence Rates](https://digital.nhs.uk/data-and-information/publications/statistical/nhs-sickness-absence-rates)
- [A&E Attendances and Emergency Admissions](https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/)
- [A&E Data Quality Guidance](https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/data-quality/)


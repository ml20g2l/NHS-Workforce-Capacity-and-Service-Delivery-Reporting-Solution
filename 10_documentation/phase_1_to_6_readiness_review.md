# Phase 1–6 Readiness Review

## Decision

**Conditionally ready for Phase 7.**

The design and source-control artifacts are complete enough to begin the recurring-reporting simulation. The remaining hard gate is operational: the 31 Power Query expressions must be registered once in Excel, refreshed against the local folders and checked for runtime errors before Cycle 1 is recorded.

## Review scope

The review covered:

- the project brief and repository structure;
- official source coverage from April 2024 to March 2025;
- source profiling and join grain;
- KPI definitions;
- star-schema design;
- Power Query dependencies and provenance;
- data-quality rules and reconciliation;
- revision handling and reporting-scope controls;
- workbook setup documentation.

## Phase assessment

| Phase | Status | Evidence | Readiness observation |
|---|---|---|---|
| 1. Project brief | Ready | `01_project_brief/project_brief.md` | Business scenario, users, questions, scope, governance, controls, workflow, limitations and success criteria are documented. |
| 2. Sources and source register | Ready | 1 cumulative workforce ZIP, 12 absence CSVs, 12 A&E CSVs, source register and profile summary | The workforce publication contains all 12 reporting months in one cumulative extract, so 12 workforce downloads are not required. |
| 3. KPI dictionary | Ready | `10_documentation/kpi_dictionary.xlsx` | KPIs are separated by domain and distinguish official measures from analytical proxies. |
| 4. Data model design | Design ready | `10_documentation/data_model_design.*` | Natural grains and the safe Month × Organisation summary are documented. Physical fact and dimension outputs will be materialised after the refresh pipeline is runtime-tested. |
| 5. Power Query | Package ready; runtime test pending | 31 ordered `.pq` files and `power_query_control.xlsx` | Query objects cannot be embedded by the file-generation tooling. One-time Excel registration and refresh remain required. |
| 6. Data quality | Framework ready; runtime test pending | 42-rule workbook, classified queries, exceptions, file register and reconciliation | The rules distinguish observed issues from controlled tests. Counts must be re-confirmed after the queries are installed. |

## Material gaps found and upgrades completed

### 1. Controlled organisation reference

The earlier design referred to `DimOrganisation`, but no approved reference file existed.

Completed upgrade:

- created `02_source_data/reference/dim_organisation.csv`;
- retained the 148 organisation codes present in all three datasets in all 12 months;
- selected the 20 London providers in that stable intersection as the reporting cohort;
- preserved canonical names, observed aliases, region, organisation type, ICS and mapping status;
- added `dimOrganisation` to the Power Query package;
- made the clean outputs require both `RecordStatus = Accepted` and `InclusionFlag = true`.

This removes the earlier ambiguity around the intended one-region, 10–20-provider scope.

### 2. Duplicate and revised source files

The earlier folder queries loaded every CSV. A duplicate or revised file for the same month would therefore create duplicated business keys.

Completed upgrade:

- added `fnGetSourceFiles`;
- grouped files by dataset and filename reporting month;
- ordered versions using the file modified timestamp and filename;
- selected one Active version;
- classified older files as exact duplicate or non-identical revised versions;
- retained all versions in `qrySourceFileRegister`;
- added file modified timestamp, size, version rank and disposition to row provenance.

The latest file is now the only version transformed into staging. The external download or cycle manifest should still record SHA-256 hashes because the workbook file register is not an archive substitute.

### 3. September 2024 A&E schema artifact

The earlier rule placed every September provider row into `Review Required` because the official file contains six trailing extra columns with no row data.

Completed upgrade:

- canonical 22 columns remain selected by name;
- unexpected columns containing data still require review;
- blank trailing artifacts are recorded but treated as an approved schema variance.

This prevents a known harmless publication artifact from removing an entire reporting month from the clean output.

### 4. Scope-aware reconciliation

The earlier reconciliation compared only raw and accepted totals.

Completed upgrade:

- added `ReportableValue`;
- retained `RawValue`, `AcceptedValue` and the London-cohort reportable total;
- separated quality exclusions from reporting-scope exclusions.

### 5. Repository status

The root README still stated that sources had not been downloaded and the pipeline had not been built. It has been updated to reflect the current Phase 1–6 state and the Phase 7 runtime gate.

## Phase 7 entry checks

Do not record Reporting Cycle 1 until all checks below pass:

1. `tblParameters` contains the four valid folder paths and the two reporting-month parameters.
2. All 31 queries are registered using the exact names and order in `03_power_query/README.md`.
3. `qrySourceFileRegister` shows one Active file for each available dataset-month.
4. The three staging queries refresh without errors.
5. `qryDataQualityReconciliation` shows that raw, accepted and reportable differences are explained.
6. Clean outputs contain only the 20-provider London cohort.
7. The September 2024 A&E file is present after the approved blank-column projection.
8. No unresolved Critical failure remains.

## Items intentionally deferred to Phase 7

- cycle-specific input folders or manifests;
- Cycle 1, Cycle 2 and Cycle 3 refresh snapshots;
- append-only refresh and change logs;
- comparison of overlapping historical values between cycles;
- the controlled duplicate or revision test file;
- Q1 and July-extended reporting outputs.

These are simulation deliverables rather than defects in the Phase 1–6 design.

## Overall conclusion

Phase 1–6 is structurally sound after the upgrades above. The project should proceed to Phase 7 only after the one-time Excel query registration and a successful full refresh. That runtime test is necessary because static review of M expressions cannot prove that the local Excel engine, privacy settings and folder paths will execute every query successfully.

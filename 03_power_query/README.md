# Phase 5 — Power Query Build

## Purpose

This package provides the Excel parameter table and Power Query M expressions for repeatable monthly ingestion of:

- NHS Workforce Statistics;
- NHS Sickness Absence Rates;
- A&E Attendances and Emergency Admissions.

The queries preserve row-level provenance and classify every source row before it is used in reporting.

## Files

- `power_query_control.xlsx` — Excel control workbook containing the named table `tblParameters`, query catalogue, setup steps and validation rules.
- `prepare_workforce_extract.ps1` — extracts the required organisation-and-staff-group CSV from the preserved workforce ZIP.
- `m/` — Power Query M expressions, numbered in the recommended creation order.

Excel workbook generation tools cannot embed or edit Power Query connection objects directly. Create blank queries in Excel and paste each supplied M expression into **Advanced Editor**, using the query name shown below.

## 1. Prepare the workforce CSV

The workforce source is distributed as a ZIP archive. Excel Power Query does not provide a simple, reliable folder-combine experience for an arbitrary ZIP container.

Run this command from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File ".\03_power_query\prepare_workforce_extract.ps1"
```

The script:

1. leaves the raw ZIP unchanged;
2. extracts only `NHS Workforce Statistics, March 2025 Staff Group and Organisation.csv`;
3. writes it to `04_processed_data/staging/workforce/`;
4. creates a SHA-256 extraction manifest.

Generated staging CSV files are excluded from Git because they can be reproduced from the preserved raw ZIP.

## 2. Open the control workbook

Open `03_power_query/power_query_control.xlsx`.

The `Parameters` sheet contains the named Excel table `tblParameters` with:

| ParameterName | ParameterValue |
|---|---|
| WorkforceFolder | Local workforce staging folder |
| AbsenceFolder | Local raw absence folder |
| ActivityFolder | Local raw service-activity folder |
| ReportingStartMonth | 2024-04-01 |
| ReportingEndMonth | 2025-03-01 |

Update the three folder paths if the project is moved or cloned to another computer.

## 3. Create queries in order

In Excel:

1. Select **Data → Get Data → From Other Sources → Blank Query**.
2. Rename the query using the name below.
3. Select **Home → Advanced Editor**.
4. Replace the contents with the matching `.pq` file.
5. Select **Done**.

| Order | Query name | M file | Recommended load |
|---:|---|---|---|
| 1 | `fnGetParameter` | `00_fnGetParameter.pq` | Connection only |
| 2 | `pWorkforceFolder` | `01_pWorkforceFolder.pq` | Connection only |
| 3 | `pAbsenceFolder` | `02_pAbsenceFolder.pq` | Connection only |
| 4 | `pActivityFolder` | `03_pActivityFolder.pq` | Connection only |
| 5 | `pReportingStartMonth` | `04_pReportingStartMonth.pq` | Connection only |
| 6 | `pReportingEndMonth` | `05_pReportingEndMonth.pq` | Connection only |
| 7 | `fnCleanOrganisationCode` | `10_fnCleanOrganisationCode.pq` | Connection only |
| 8 | `fnParseDate` | `11_fnParseDate.pq` | Connection only |
| 9 | `fnParseNumber` | `12_fnParseNumber.pq` | Connection only |
| 10 | `fnMonthFromFileName` | `13_fnMonthFromFileName.pq` | Connection only |
| 11 | `fnMonthFromAEPeriod` | `14_fnMonthFromAEPeriod.pq` | Connection only |
| 12 | `fnTransformWorkforceFile` | `20_fnTransformWorkforceFile.pq` | Connection only |
| 13 | `fnTransformAbsenceFile` | `21_fnTransformAbsenceFile.pq` | Connection only |
| 14 | `fnTransformActivityFile` | `22_fnTransformActivityFile.pq` | Connection only |
| 15 | `stgWorkforceFiles` | `30_stgWorkforceFiles.pq` | Connection only |
| 16 | `stgAbsenceFiles` | `31_stgAbsenceFiles.pq` | Connection only |
| 17 | `stgServiceFiles` | `32_stgServiceFiles.pq` | Connection only |
| 18 | `dqWorkforceClassified` | `60_dqWorkforceClassified.pq` | Connection only |
| 19 | `dqAbsenceClassified` | `61_dqAbsenceClassified.pq` | Connection only |
| 20 | `dqServiceActivityClassified` | `62_dqServiceActivityClassified.pq` | Connection only |
| 21 | `qryWorkforceClean` | `40_qryWorkforceClean.pq` | Data Model or worksheet preview |
| 22 | `qryAbsenceClean` | `41_qryAbsenceClean.pq` | Data Model or worksheet preview |
| 23 | `qryServiceActivityClean` | `42_qryServiceActivityClean.pq` | Data Model or worksheet preview |
| 24 | `qryPowerQueryExceptions` | `50_qryPowerQueryExceptions.pq` | Worksheet table |
| 25 | `qryPowerQueryRefreshSummary` | `51_qryPowerQueryRefreshSummary.pq` | Worksheet table |
| 26 | `qryDataQualityRuleResults` | `63_dqRuleResults.pq` | Worksheet table |
| 27 | `qryDataQualityReconciliation` | `64_dqReconciliation.pq` | Worksheet table |

## 4. Folder-import controls

Each folder query:

1. reads the configured folder;
2. removes hidden, system and temporary Excel files;
3. accepts `.csv` files only;
4. applies the dataset transformation function;
5. standardises column names;
6. adds source filename and fixed UTC load timestamp;
7. validates the expected schema;
8. parses dates and numeric fields without silently discarding failed conversions;
9. cleans organisation codes using trim, clean and uppercase;
10. retains all staged rows with a status and reason.

## 5. Required provenance columns

Every staging and clean query retains:

| Column | Meaning |
|---|---|
| `SourceFile` | Exact file name that supplied the row |
| `SourceDataset` | Controlled dataset label |
| `ReportingMonth` | First day of the normalized reporting month |
| `LoadTimestamp` | Fixed UTC timestamp for the query refresh |
| `RecordStatus` | Accepted, Review Required or Rejected |
| `ValidationReason` | Semicolon-separated explanation of all detected issues |

`OrganisationCode` is also retained so exceptions can be traced to the affected provider where available. The exception query contains Review Required and Rejected rows.

## 6. Record-status rules

| Status | Meaning | Reporting use |
|---|---|---|
| `Accepted` | Required schema and row checks passed | Included in clean output |
| `Review Required` | The record may be usable but requires a documented decision, such as a renamed organisation, unexpected ignored column or filename/date mismatch | Excluded from clean output until reviewed |
| `Rejected` | Required fields, types, ranges or schema failed | Excluded from clean output |

The clean queries retain `Accepted` rows only. The `stg...` and `dq...Classified` queries preserve all records and statuses.

## 7. Dataset-specific controls

### Workforce

- Expected 13-column organisation-and-staff-group schema.
- `DataType` must be `HC` or `FTE`.
- `MeasureValue` must be numeric and non-negative.
- `Staff Group = Total` is retained because Phase 4 uses it in a separate organisation-month aggregate.
- The loaded staff-group fact must later exclude the Total member to prevent double counting.

### Sickness absence

- Expected 11-column monthly organisation schema.
- Row month is compared with the `YYYY-MM` filename token.
- FTE days must be numeric and non-negative.
- Sickness absence rate must be between 0 and 100.
- Published rate is reconciled to `FTEDaysLost / FTEDaysAvailable × 100`.
- A difference above 0.02 percentage points is classified as Review Required.

### A&E activity

- Exactly 22 canonical source columns are selected.
- Unexpected columns are ignored but generate Review Required.
- All 18 activity measures must be numeric and non-negative.
- The period text is reconciled to the month in the source filename.
- Each over-four-hour count must not exceed its corresponding attendance count.
- `Org Code = TOTAL` is marked `Rejected` for the provider-level fact, retained in staging and omitted from the clean provider table.
- Booked-appointment columns remain separate and are not added to headline attendance totals.

## 8. Refresh checks

Before using the clean tables:

1. confirm the expected files appear in `qryPowerQueryRefreshSummary`;
2. confirm all reporting months from April 2024 to March 2025 are present;
3. review all Review Required and Rejected counts;
4. open `qryPowerQueryExceptions` and investigate rejection reasons;
5. confirm there are no duplicate candidate keys at the intended grains;
6. reconcile staged, accepted, Review Required and Rejected row counts and measure totals;
7. do not publish if a critical schema or required-field failure is unresolved.

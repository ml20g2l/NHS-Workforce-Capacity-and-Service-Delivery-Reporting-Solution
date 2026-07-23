# NHS Workforce Capacity & Service Delivery Reporting

## Phase 2 Source Notes

| Document field | Detail |
|---|---|
| Reporting period | April 2024 to March 2025 |
| Data classification | Public, aggregate NHS statistics |
| Raw source files | 25 distribution files: 1 workforce ZIP, 12 absence CSVs and 12 A&E CSVs |
| Recommended common grain | Reporting month × organisation |
| Required common join key | Normalised month end + controlled organisation code |
| Overall assessment | Usable with controls |

## 1. Purpose

These notes document the observed structure, grain, identifiers, measures, dimensions and data-quality risks in the Phase 2 source files. The conclusions are based on the downloaded files, not only on publication descriptions.

The raw files are preserved under `02_source_data/raw/`. File size, SHA-256 hash, source URL and download timestamp are recorded in `02_source_data/reference/phase2_download_manifest.csv`.

## 2. Source Selection

### 2.1 NHS Workforce Statistics

Selected source:

- `02_source_data/raw/workforce/nhs_workforce_statistics_2025-03_csv.zip`
- Organisation-level member used for profiling: `NHS Workforce Statistics, March 2025 Staff Group and Organisation.csv`

The March 2025 ZIP is a cumulative distribution package. Its organisation-and-staff-group CSV contains the complete April 2024 to March 2025 window, so 12 separate workforce downloads are unnecessary.

Official publication:

- [NHS Workforce Statistics – March 2025](https://digital.nhs.uk/data-and-information/publications/statistical/nhs-workforce-statistics/march-2025)

### 2.2 NHS Sickness Absence Rates

Selected sources:

- 12 monthly organisation-level CSV files from April 2024 to March 2025
- File naming convention: `nhs_sickness_absence_YYYY-MM.csv`

Each selected file contains one reporting month.

Official publication series:

- [NHS Sickness Absence Rates](https://digital.nhs.uk/data-and-information/publications/statistical/nhs-sickness-absence-rates)

### 2.3 A&E Attendances and Emergency Admissions

Selected sources:

- 12 monthly provider-level CSV files from April 2024 to March 2025
- File naming convention: `ae_activity_YYYY-MM.csv`
- Revised official CSVs were selected where the 2024-25 publication page supplied them.

Each selected file contains one reporting month plus one published aggregate total row.

Official publication:

- [A&E Attendances and Emergency Admissions 2024-25](https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/ae-attendances-and-emergency-admissions-2024-25/)
- [A&E data-quality guidance](https://www.england.nhs.uk/statistics/statistical-work-areas/ae-waiting-times-and-activity/data-quality/)

## 3. Observed Dataset Profiles

| Dataset | Files | Accepted rows in period | Months | Distinct organisation codes | Candidate-key duplicate rows |
|---|---:|---:|---:|---:|---:|
| Workforce | 1 cumulative ZIP | 125,194 | 12 | 253 | 0 |
| Sickness absence | 12 monthly CSVs | 3,394 | 12 | 286 | 0 |
| A&E activity | 12 monthly CSVs | 2,372 provider rows | 12 | 200 | 0 |

The A&E accepted-row count excludes one published aggregate total row from each monthly file.

Across the accepted records:

- no missing required date, organisation-code or core measure fields were observed;
- no negative core measures were observed;
- no non-numeric values were observed in the profiled measure fields;
- no sickness absence rates outside 0–100 were observed;
- no duplicate candidate keys were observed at the stated grains.

These results describe the current files only. The same checks should run on every refresh.

## 4. Workforce Structure

### 4.1 Observed Grain

The organisation-level workforce file is unique at:

> Date × Org Code × Staff Group × Data Type

Observed fields:

- `Date`
- `NHSE_Region_Code`
- `NHSE_Region_Name`
- `ICS code`
- `ICS name`
- `Org Code`
- `Org Name`
- `Cluster Group`
- `Benchmark Group`
- `Staff Group Sort Order`
- `Staff Group`
- `Data Type`
- `Total`

The requested 12-month window contains:

- 28 distinct staff-group values;
- two data types: `FTE` and `HC`;
- 247–252 organisations per month.

### 4.2 Measures and Dimensions

**Measure**

- `Total`, interpreted according to `Data Type`

**Dimensions**

- reporting month;
- organisation;
- NHSE region;
- ICS;
- cluster group;
- benchmark group;
- staff group;
- data type.

### 4.3 Required Controls

`Staff Group = Total` is an aggregate row. It must not be added to its component staff groups.

`FTE` and `HC` are different measures. They must not be summed together.

For the common organisation-month reporting table:

1. filter to `Staff Group = Total`;
2. retain candidate-key uniqueness at `Date + Org Code + Data Type`;
3. pivot `FTE` and `HC` into separate measure columns;
4. retain staff-group detail in a separate workforce fact table.

## 5. Sickness Absence Structure

### 5.1 Observed Grain

The selected monthly CSV is unique at:

> DATE × ORG_CODE

Observed fields:

- `DATE`
- `NHSE_REGION_CODE`
- `NHSE_REGION_NAME`
- `ICS_CODE`
- `ICS_NAME`
- `ORG_CODE`
- `ORG_NAME`
- `ORG_TYPE`
- `FTE_DAYS_LOST`
- `FTE_DAYS_AVAILABLE`
- `SICKNESS_ABSENCE_RATE_PERCENT`

Monthly organisation counts decline from 285 in April–September 2024 to 280 in December 2024–March 2025. This should be treated as a coverage and organisation-change signal, not automatically as a data error.

### 5.2 Measures and Dimensions

**Measures**

- FTE days lost;
- FTE days available;
- sickness absence rate, stored as percentage points from 0 to 100.

**Dimensions**

- reporting month;
- organisation;
- organisation type;
- NHSE region;
- ICS.

### 5.3 Staff-Group Limitation

The selected 11-column monthly CSV does not contain a staff-group field. It cannot support staff-group sickness absence analysis.

The first reporting version should therefore use absence at organisation-month grain. If staff-group absence becomes a required KPI, the separate “by reason, staff group and organisation” files must be downloaded and profiled as an additional source. The current source must not be described as staff-group level.

## 6. A&E Structure

### 6.1 Observed Grain

After excluding the published aggregate total row, the source is unique at:

> Normalised Period × Org Code

A&E type is encoded across wide measure columns rather than represented as a row-level dimension.

Core identifiers:

- `Period`
- `Org Code`
- `Parent Org`
- `Org name`

Core measure groups:

- attendances by A&E type;
- booked-appointment attendances;
- attendances over four hours;
- waits of 4–12 hours and 12+ hours following decision to admit;
- emergency admissions through A&E;
- other emergency admissions.

### 6.2 Published Total Row

Every monthly file contains one aggregate total row. Its text is not completely consistent:

- `TOTAL`
- `Total`
- values with trailing spaces, such as `Total `

The provider pipeline should normalise case and whitespace before excluding `Org Code = TOTAL`. The total row should be retained separately for reconciliation against provider sums.

### 6.3 September 2024 Schema Artifact

The September 2024 file has 28 raw columns rather than the canonical 22. Six trailing columns are empty in the records, except for an unexpected header value `a`.

The ingestion process should select the 22 canonical named columns explicitly and quarantine any unexpected extra columns. Positional column selection should not be used.

### 6.4 Revisions

Revised official CSVs were used for:

- April 2024;
- July 2024;
- October 2024;
- November 2024;
- February 2025.

Revision handling is therefore a core reporting control rather than an optional enhancement. Each refresh should compare file hashes and overlapping-period totals with the prior archive.

## 7. Join Assessment

### 7.1 Observed Coverage

Using A&E provider organisation-months as the operational universe:

- mean A&E-to-workforce code-month match: 75.8%;
- minimum A&E-to-workforce match: 75.6%;
- mean A&E-to-absence match: 77.8%;
- minimum A&E-to-absence match: 77.3%;
- mean match across all three sources: 75.8%;
- minimum match across all three sources: 75.3%.

The incomplete match is not evidence that all unmatched A&E rows are erroneous. A&E includes provider types and organisation codes that may not be represented in the HCHS workforce and sickness absence sources.

### 7.2 Stable Cohort

Observed across the full 12-month window:

- 194 A&E organisation codes are present in every month;
- 148 organisation codes are present in all three datasets in every month.

The 148-code stable intersection is the safest initial selection universe. The planned regional cohort of 10–20 providers should be selected from this intersection after applying a controlled organisation reference and provider-type filter.

### 7.3 Recommended Join Strategy

1. Create a dated organisation reference table with canonical code, name, region, organisation type, valid-from date, valid-to date and inclusion flag.
2. Normalise all source dates to month end.
3. Filter A&E to accepted provider rows and workforce to `Staff Group = Total`.
4. Aggregate or pivot each source independently to month × organisation.
5. Test uniqueness before joining.
6. Join on organisation code + reporting month.
7. Report unmatched codes and row retention before publishing KPIs.
8. Use organisation names only as display attributes.

Organisation names must not be used as primary join keys.

## 8. Safest Common Reporting Grain

The safest common reporting grain is:

> Reporting month × controlled provider organisation

This grain supports:

- workforce FTE and headcount;
- FTE days available and lost;
- organisation-level sickness absence rate;
- A&E attendance and admission measures;
- derived organisation-level capacity and pressure indicators.

Staff-group workforce reporting should remain a separate drill-down table. Staff-group sickness absence is out of scope until the more detailed absence source is added.

## 9. Fields That Should Not Be Used

| Dataset | Field or record | Decision | Reason |
|---|---|---|---|
| All | Organisation name as a join key | Do not use | Names can change and differ by source |
| Workforce | `Staff Group = Total` combined with component rows | Do not aggregate together | Double-counting risk |
| Workforce | `FTE` combined with `HC` | Do not aggregate together | Different units |
| Absence | Any inferred staff-group classification | Do not create | No staff-group field in selected source |
| A&E | `Parent Org` as a cross-source join key | Do not use | It is a hierarchy/display field, not the controlled provider identifier |
| A&E | Published `TOTAL` row in provider fact | Exclude | Aggregate summary row |
| A&E | September trailing blank columns and header `a` | Exclude | Schema artifact outside the canonical 22 fields |
| All | Unmatched records silently dropped by an inner join | Do not allow | Would remove approximately one quarter of the A&E provider universe |

## 10. Recommended Automated Intake Tests

Every monthly refresh should test:

1. expected file presence and non-zero size;
2. SHA-256 change from the prior archived version;
3. expected reporting month in each monthly file;
4. expected canonical columns and unexpected extra columns;
5. required date and organisation-code completeness;
6. candidate-key uniqueness at the accepted grain;
7. numeric type and non-negative measure checks;
8. sickness absence rate between 0 and 100;
9. exactly one A&E published total row per monthly file;
10. no `TOTAL` organisation code in the provider output;
11. organisation-code reference coverage;
12. row retention and measure reconciliation before and after joins;
13. changes to previously published months.

## 11. Assumptions and Open Decisions

- The first release will use one region and 10–20 providers selected from the stable all-three-source cohort.
- The region has not yet been selected.
- A dated organisation reference table still needs to be created.
- Staff-group absence is deferred unless the detailed absence source is explicitly added.
- A&E type will initially remain encoded in separate measure columns; reshaping to a long A&E-type dimension can be considered during Power Query design.
- The derived `Estimated Available FTE` will remain labelled as a proxy rather than actual staffed capacity.

## 12. Supporting Artifacts

- `10_documentation/source_register.xlsx`
- `10_documentation/phase2_profile_summary.json`
- `02_source_data/reference/phase2_download_manifest.csv`
- `02_source_data/download_phase2_files.ps1`


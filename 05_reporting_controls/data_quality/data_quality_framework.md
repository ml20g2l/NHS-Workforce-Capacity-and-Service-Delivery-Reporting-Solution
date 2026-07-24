# NHS Workforce Capacity and Service Delivery Data Quality Framework

## Purpose

This framework prevents invalid or unresolved records from disappearing during
Power Query cleaning. Every in-scope reporting record is retained with source
lineage and assigned one of three controlled statuses:

| Status | Definition | Reporting treatment |
|---|---|---|
| Accepted | All applicable automated controls passed. | Included in clean reporting outputs. |
| Review Required | The record may be usable but requires a documented schema, mapping or reconciliation decision. | Excluded until reviewed and approved. |
| Rejected | A required schema, key, type, range, uniqueness or reporting-grain rule failed. | Excluded from clean outputs and retained in the exception log. |

The detailed 39-rule matrix is maintained in
`05_reporting_controls/data_quality/data_quality_framework.xlsx`.

## Confirmed reporting grains

| Dataset | Confirmed source grain used by the controls | Candidate key |
|---|---|---|
| Workforce | Reporting month × organisation × staff group × data type | `ReportingMonth + OrganisationCode + StaffGroupName + DataType` |
| Absence | Reporting month × organisation | `ReportingMonth + OrganisationCode` |
| A&E activity | Reporting month × provider organisation | `ReportingMonth + OrganisationCode` after excluding the published `TOTAL` row |

Organisation names are descriptive fields and are not used as join keys.

## Observed source findings

The following findings are based on the local official NHS files covering
April 2024 to March 2025.

### Workforce

- One cumulative organisation-and-staff-group extract contains 125,194 rows in
  the reporting window.
- The confirmed schema contains 13 columns.
- No missing required fields, invalid dates, invalid numbers, negative measures,
  duplicate composite keys or organisation-name variants were observed.
- Both published data types are present: 62,597 FTE rows and 62,597 HC rows.

### Sickness absence

- Twelve monthly files contain 3,394 records using one stable 11-column schema.
- No missing required fields, invalid dates, invalid numbers, negative values,
  out-of-range rates, duplicate month-organisation keys or filename-month
  mismatches were observed.
- Four organisation codes use more than one published organisation name during
  the reporting window: `RAX`, `RW1`, `RWD` and `RRE`.
- These published name changes affect 48 rows and are classified as
  `Review Required` pending organisation-mapping confirmation.

### A&E activity

- Twelve monthly files contain 2,384 rows and all retain the 22 canonical
  source fields.
- The September 2024 file includes six additional headers: five blank headers
  and one header named `a`. Canonical fields remain available, but affected
  provider rows are classified as `Review Required`.
- Each file contains one published aggregate `TOTAL` row. The 12 aggregate rows
  are retained for reconciliation and classified as `Rejected` for the
  provider-level fact to prevent double counting.
- No missing provider codes, invalid or negative activity measures,
  provider-level duplicate keys, filename-period mismatches, or cases where an
  over-four-hour count exceeds its corresponding attendance count were
  observed.
- Three provider codes use multiple published names: `RAX`, `RW1` and `RWD`.

## Current source-profile classification

| Dataset | Raw rows | Accepted | Review Required | Rejected | Difference |
|---|---:|---:|---:|---:|---:|
| Workforce | 125,194 | 125,194 | 0 | 0 | 0 |
| Absence | 3,394 | 3,346 | 48 | 0 | 0 |
| A&E activity | 2,384 | 2,142 | 230 | 12 | 0 |

These figures are profiling evidence from the current local files. The Excel
Power Query refresh outputs remain the operational source of truth after the
queries are installed and refreshed.

## Power Query implementation

The Phase 6 implementation adds the following queries:

| Query | Purpose |
|---|---|
| `fnMonthFromAEPeriod` | Parses the official `MSitAE-MONTH-YYYY` period text. |
| `dqWorkforceClassified` | Applies workforce duplicate and organisation-name consistency controls. |
| `dqAbsenceClassified` | Applies absence duplicate and organisation-name consistency controls. |
| `dqServiceActivityClassified` | Applies A&E grain, duplicate and organisation-name consistency controls. |
| `qryDataQualityRuleResults` | Returns record counts by dataset, file, month and status. |
| `qryDataQualityReconciliation` | Reconciles row counts and additive source measures to accepted totals. |

All clean queries now read from the classified queries and include only
`Accepted` records. `Review Required` and `Rejected` records remain available
in `qryPowerQueryExceptions`.

## Reconciliation controls

Every refresh must demonstrate:

1. raw rows equal Accepted + Review Required + Rejected;
2. additive raw totals reconcile to totals segmented by record status;
3. every difference has a traceable `ValidationReason`;
4. all six provenance fields are present:
   `SourceFile`, `SourceDataset`, `ReportingMonth`, `LoadTimestamp`,
   `RecordStatus` and `ValidationReason`;
5. percentages are recalculated or weighted appropriately and are never summed;
6. booked A&E appointment fields remain separate subsets and are not added
   again to headline attendance totals.

## Observed issues versus controlled tests

Observed source issues are limited to evidence found in the supplied files:

- A&E September 2024 schema drift;
- published A&E aggregate rows;
- a small number of organisation-name changes.

Missing columns, missing identifiers, duplicates, negative values,
out-of-range rates, filename-month mismatches, unmatched reference codes and
reconciliation breaks are maintained as controlled pipeline tests. They are not
presented as issues discovered in the current source data.

## Pending dependency

The unmatched-organisation rule requires the approved `DimOrganisation`
reference table. Until that reference is populated, the rule remains a
controlled test and cross-source coverage difference must not be described as a
data error.

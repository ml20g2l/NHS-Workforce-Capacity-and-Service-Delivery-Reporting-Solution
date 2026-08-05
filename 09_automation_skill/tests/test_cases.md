# Acceptance and failure test cases

| ID | Scenario | Expected result |
|---|---|---|
| T01 | One valid monthly file for each dataset; all required fields present | Complete refresh; accepted records, KPI summary and all outputs created |
| T02 | Workforce file missing `Data Type` | Critical schema failure; `run_failure.json` and file inventory created; no complete refresh |
| T03 | Activity filename period differs from `Period` field | Review-required exception; no silent substitution |
| T04 | Duplicate activity file for one reporting month | Both files retained in file inventory; duplicate candidate logged for review |
| T05 | Absence rate outside 0–100% | Affected record rejected with rule ID and reason |
| T06 | A&E over-four-hour count greater than total attendances | Affected record rejected; KPI excluded from accepted facts |
| T07 | Unknown organisation code | Review-required exception; record excluded from reportable facts but retained in quality output |
| T08 | Approved but out-of-cohort organisation | Review-required scope exception; retained for audit only |
| T09 | No previous refresh control | Current outputs created; comparison status set to `Not available` |
| T10 | Current refresh changes a prior accepted KPI total | Reconciliation output shows current, prior, difference and explanation status |
| T11 | Commentary generation | Commentary uses observed language and labels proxies; it makes no causal claim |

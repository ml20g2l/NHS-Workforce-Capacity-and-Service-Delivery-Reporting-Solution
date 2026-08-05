# Validation rules and failure handling

## Validation gates

| Gate | Rule | Severity | Outcome |
|---|---|---|---|
| Input presence | All three dataset inputs, reference table and KPI dictionary supplied | Critical | Stop refresh |
| File extension | Source file is CSV; ignore hidden/system files | High | Log and exclude file |
| Filename period | A filename period is recognised and agrees with in-file period where both exist | High | `Review Required`; stop if no valid file remains for a required dataset |
| Schema | Every required field is present before transformation | Critical | Stop refresh |
| Type conversion | Dates and numeric measures parse successfully | High | Reject affected record; stop if conversion failure prevents a dataset from being processed |
| Organisation code | Code is present, trimmed and uppercase | High | Reject missing code; map known code; review unmatched code |
| Workforce validity | FTE/headcount non-negative; supported `Data Type` only | High | Reject invalid record |
| Absence validity | Available days positive; lost days non-negative; rate between 0 and 100 percent | High | Reject invalid record |
| Activity validity | Attendance, over-four-hour attendance, admissions and waits non-negative; over-four-hour attendance does not exceed total attendance | High | Reject invalid record |
| Duplicate candidate key | Same reporting month, organisation and staff group/data type or activity row appears more than once | Medium | `Review Required`; do not deduplicate silently |
| Reference scope | Organisation not in approved reporting cohort | Medium | `Review Required`; retain for audit, exclude from reportable facts |
| Reconciliation | Current file/row/total differences versus previous refresh are explained | Medium | Warning and exception entry |

## Status rules

- **Accepted:** Required fields, schema, period and validity rules pass; organisation is mapped and in scope.
- **Rejected:** A record has a validity failure that makes a KPI unsafe, such as no organisation code, invalid numeric field or impossible activity relationship.
- **Review Required:** A record is structurally readable but needs an owner decision, such as unmatched organisation, duplicate candidate, out-of-scope row or filename-period mismatch.

## Failure handling

1. Never overwrite a prior successful output folder.
2. Write a `run_failure.json` with timestamp, failed gate, affected files and next action before exiting on a critical error.
3. Preserve the file inventory and any completed pre-validation results.
4. Do not generate a `Complete` refresh log, KPI summary or management commentary if a critical gate fails.
5. If no previous refresh is available, produce the current controls, set comparison status to `Not available`, and do not invent changes.
6. If the KPI dictionary conflicts with the implemented approved list, stop and request governance review.

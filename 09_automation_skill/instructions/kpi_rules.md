# Approved KPI rules

Calculate only the following measures. Preserve their classification in `kpi_summary.csv` and management commentary.

| KPI | Formula / source | Grain | Classification |
|---|---|---|---|
| Workforce FTE | Sum of accepted workforce FTE | Month × organisation | Official source measure |
| Headcount | Sum of accepted workforce headcount | Month × organisation | Official source measure |
| Sickness absence rate | FTE days lost ÷ FTE days available | Month × organisation | Official source measure when sourced directly; weighted calculation for aggregate reporting |
| FTE days lost | Sum of accepted absence `FTE_DAYS_LOST` | Month × organisation | Official source measure |
| Total attendances | Sum of accepted A&E attendance components | Month × organisation | Official source measure |
| Emergency admissions | Sum of accepted emergency-admission components | Month × organisation | Official source measure |
| Attendances over four hours | Sum of accepted over-four-hour components | Month × organisation | Official source measure |
| Four-hour performance | 1 − (attendances over four hours ÷ total attendances) | Month × organisation | Analytical calculation from official aggregate components |
| 12+ hour DTA waits | Sum of accepted 12+ hour DTA waits | Month × organisation | Official source measure |
| Estimated available FTE | Workforce FTE × (1 − sickness absence rate) | Month × organisation | Analytical proxy |
| Attendances per available FTE | Total attendances ÷ estimated available FTE | Month × organisation | Analytical proxy |
| Demand-to-capacity pressure index | Total attendances ÷ estimated available FTE | Month × organisation | Analytical proxy |

Never call a proxy an official NHS standard, target or clinical productivity measure. Round only in presentation outputs, not before reconciliation.

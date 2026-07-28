let
    Source = qryAbsenceClean,
    AddMonthKey = Table.AddColumn(
        Source,
        "MonthKey",
        each Date.Year([ReportingMonth]) * 100 + Date.Month([ReportingMonth]),
        Int64.Type
    ),
    AddOrganisationKey = Table.AddColumn(
        AddMonthKey,
        "OrganisationKey",
        each [OrganisationCode],
        type text
    ),
    AddAbsenceRate = Table.AddColumn(
        AddOrganisationKey,
        "SicknessAbsenceRate",
        each
            if [SicknessAbsenceRatePercent] = null then
                null
            else
                [SicknessAbsenceRatePercent] / 100,
        type nullable number
    ),
    Selected = Table.SelectColumns(
        AddAbsenceRate,
        {
            "MonthKey",
            "ReportingMonth",
            "OrganisationKey",
            "FTEDaysLost",
            "FTEDaysAvailable",
            "SicknessAbsenceRate",
            "SicknessAbsenceRatePercent",
            "RecalculatedAbsenceRatePercent",
            "AbsenceRateVariance"
        }
    )
in
    Selected

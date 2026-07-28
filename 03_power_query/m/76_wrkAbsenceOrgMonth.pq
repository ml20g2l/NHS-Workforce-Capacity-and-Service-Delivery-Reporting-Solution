let
    Source = FactAbsence,
    Selected = Table.SelectColumns(
        Source,
        {
            "MonthKey",
            "ReportingMonth",
            "OrganisationKey",
            "FTEDaysLost",
            "FTEDaysAvailable",
            "SicknessAbsenceRate"
        }
    )
in
    Selected

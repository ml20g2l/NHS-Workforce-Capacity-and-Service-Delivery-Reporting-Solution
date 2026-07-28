let
    Source = FactServiceActivity,
    Selected = Table.SelectColumns(
        Source,
        {
            "MonthKey",
            "ReportingMonth",
            "OrganisationKey",
            "TotalAttendances",
            "AttendancesWithin4Hours",
            "AttendancesOver4Hours",
            "FourHourPerformanceRate",
            "TotalEmergencyAdmissions",
            "AdmissionsPerAttendanceRate",
            "Waits12PlusHoursDTA",
            "DTA12PlusPerEmergencyAdmissionRate"
        }
    )
in
    Selected

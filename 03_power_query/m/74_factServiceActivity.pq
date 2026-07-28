let
    Source = qryServiceActivityClean,
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
    AddTotalAttendances = Table.AddColumn(
        AddOrganisationKey,
        "TotalAttendances",
        each List.Sum({[AttendancesType1], [AttendancesType2], [AttendancesOther]}),
        type nullable number
    ),
    AddOver4Hours = Table.AddColumn(
        AddTotalAttendances,
        "AttendancesOver4Hours",
        each List.Sum({[Over4HoursType1], [Over4HoursType2], [Over4HoursOther]}),
        type nullable number
    ),
    AddWithin4Hours = Table.AddColumn(
        AddOver4Hours,
        "AttendancesWithin4Hours",
        each [TotalAttendances] - [AttendancesOver4Hours],
        type nullable number
    ),
    AddFourHourPerformance = Table.AddColumn(
        AddWithin4Hours,
        "FourHourPerformanceRate",
        each
            if [TotalAttendances] = null or [TotalAttendances] = 0 then
                null
            else
                [AttendancesWithin4Hours] / [TotalAttendances],
        type nullable number
    ),
    AddEmergencyAdmissions = Table.AddColumn(
        AddFourHourPerformance,
        "TotalEmergencyAdmissions",
        each
            List.Sum({
                [EmergencyAdmissionsViaAEType1],
                [EmergencyAdmissionsViaAEType2],
                [EmergencyAdmissionsViaAEOther],
                [OtherEmergencyAdmissions]
            }),
        type nullable number
    ),
    AddAdmissionRate = Table.AddColumn(
        AddEmergencyAdmissions,
        "AdmissionsPerAttendanceRate",
        each
            if [TotalAttendances] = null or [TotalAttendances] = 0 then
                null
            else
                [TotalEmergencyAdmissions] / [TotalAttendances],
        type nullable number
    ),
    AddLongWaitProxy = Table.AddColumn(
        AddAdmissionRate,
        "DTA12PlusPerEmergencyAdmissionRate",
        each
            if [TotalEmergencyAdmissions] = null
                or [TotalEmergencyAdmissions] = 0 then
                null
            else
                [Waits12PlusHoursDTA] / [TotalEmergencyAdmissions],
        type nullable number
    ),
    Selected = Table.SelectColumns(
        AddLongWaitProxy,
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
            "Waits4To12HoursDTA",
            "Waits12PlusHoursDTA",
            "DTA12PlusPerEmergencyAdmissionRate"
        }
    )
in
    Selected

let
    DateRows = Table.SelectColumns(
        DimDate,
        {
            "MonthKey",
            "ReportingMonth",
            "MonthLabel",
            "FinancialYear",
            "FinancialQuarter",
            "FinancialMonthNumber"
        }
    ),
    OrganisationRows = Table.RenameColumns(
        Table.SelectColumns(
            Table.SelectRows(
                dimOrganisation,
                each [InclusionFlag] = true
            ),
            {
                "OrganisationCode",
                "CanonicalOrganisationName",
                "OrganisationType",
                "RegionName",
                "ICSName"
            }
        ),
        {{"OrganisationCode", "OrganisationKey"}}
    ),
    AddOrganisationTable = Table.AddColumn(
        DateRows,
        "_Organisations",
        each OrganisationRows,
        type table
    ),
    Scaffold = Table.ExpandTableColumn(
        AddOrganisationTable,
        "_Organisations",
        {
            "OrganisationKey",
            "CanonicalOrganisationName",
            "OrganisationType",
            "RegionName",
            "ICSName"
        },
        {
            "OrganisationKey",
            "OrganisationName",
            "OrganisationType",
            "RegionName",
            "ICSName"
        }
    ),
    JoinWorkforce = Table.NestedJoin(
        Scaffold,
        {"MonthKey", "OrganisationKey"},
        wrkWorkforceOrgMonth,
        {"MonthKey", "OrganisationKey"},
        "_Workforce",
        JoinKind.LeftOuter
    ),
    ExpandWorkforce = Table.ExpandTableColumn(
        JoinWorkforce,
        "_Workforce",
        {"WorkforceHeadcount", "WorkforceFTE"},
        {"WorkforceHeadcount", "WorkforceFTE"}
    ),
    JoinAbsence = Table.NestedJoin(
        ExpandWorkforce,
        {"MonthKey", "OrganisationKey"},
        wrkAbsenceOrgMonth,
        {"MonthKey", "OrganisationKey"},
        "_Absence",
        JoinKind.LeftOuter
    ),
    ExpandAbsence = Table.ExpandTableColumn(
        JoinAbsence,
        "_Absence",
        {"FTEDaysLost", "FTEDaysAvailable", "SicknessAbsenceRate"},
        {"FTEDaysLost", "FTEDaysAvailable", "SicknessAbsenceRate"}
    ),
    JoinService = Table.NestedJoin(
        ExpandAbsence,
        {"MonthKey", "OrganisationKey"},
        wrkServiceOrgMonth,
        {"MonthKey", "OrganisationKey"},
        "_Service",
        JoinKind.LeftOuter
    ),
    ExpandService = Table.ExpandTableColumn(
        JoinService,
        "_Service",
        {
            "TotalAttendances",
            "AttendancesWithin4Hours",
            "AttendancesOver4Hours",
            "FourHourPerformanceRate",
            "TotalEmergencyAdmissions",
            "AdmissionsPerAttendanceRate",
            "Waits12PlusHoursDTA",
            "DTA12PlusPerEmergencyAdmissionRate"
        },
        {
            "TotalAttendances",
            "AttendancesWithin4Hours",
            "AttendancesOver4Hours",
            "FourHourPerformanceRate",
            "TotalEmergencyAdmissions",
            "AdmissionsPerAttendanceRate",
            "Waits12PlusHoursDTA",
            "DTA12PlusPerEmergencyAdmissionRate"
        }
    ),
    AddWorkforceMatchFlag = Table.AddColumn(
        ExpandService,
        "WorkforceMatchFlag",
        each [WorkforceFTE] <> null,
        type logical
    ),
    AddAbsenceMatchFlag = Table.AddColumn(
        AddWorkforceMatchFlag,
        "AbsenceMatchFlag",
        each [SicknessAbsenceRate] <> null,
        type logical
    ),
    AddServiceMatchFlag = Table.AddColumn(
        AddAbsenceMatchFlag,
        "ServiceMatchFlag",
        each [TotalAttendances] <> null,
        type logical
    ),
    AddAllSourcesMatchedFlag = Table.AddColumn(
        AddServiceMatchFlag,
        "AllSourcesMatchedFlag",
        each
            [WorkforceMatchFlag]
                and [AbsenceMatchFlag]
                and [ServiceMatchFlag],
        type logical
    ),
    AddFixedCohortFlag = Table.AddColumn(
        AddAllSourcesMatchedFlag,
        "FixedCohortFlag",
        each true,
        type logical
    ),
    AddDataQualityStatus = Table.AddColumn(
        AddFixedCohortFlag,
        "DataQualityStatus",
        each
            if [AllSourcesMatchedFlag] then
                "Complete"
            else
                "Incomplete - source match missing",
        type text
    ),
    AddEstimatedAvailableFTE = Table.AddColumn(
        AddDataQualityStatus,
        "EstimatedAvailableFTE",
        each
            if [WorkforceFTE] = null or [SicknessAbsenceRate] = null then
                null
            else
                [WorkforceFTE] * (1 - [SicknessAbsenceRate]),
        type nullable number
    ),
    AddAttendancesPerAvailableFTE = Table.AddColumn(
        AddEstimatedAvailableFTE,
        "AttendancesPerAvailableFTE",
        each
            if [EstimatedAvailableFTE] = null
                or [EstimatedAvailableFTE] = 0
                or [TotalAttendances] = null then
                null
            else
                [TotalAttendances] / [EstimatedAvailableFTE],
        type nullable number
    ),
    AddFTEPer1000Attendances = Table.AddColumn(
        AddAttendancesPerAvailableFTE,
        "FTEPer1000Attendances",
        each
            if [TotalAttendances] = null
                or [TotalAttendances] = 0
                or [WorkforceFTE] = null then
                null
            else
                [WorkforceFTE] / [TotalAttendances] * 1000,
        type nullable number
    ),
    AddPreviousMonthKey = Table.AddColumn(
        AddFTEPer1000Attendances,
        "_PreviousMonthKey",
        each
            let
                PreviousMonth = Date.AddMonths([ReportingMonth], -1)
            in
                Date.Year(PreviousMonth) * 100 + Date.Month(PreviousMonth),
        Int64.Type
    ),
    PreviousLookup = Table.RenameColumns(
        Table.SelectColumns(
            AddFTEPer1000Attendances,
            {
                "MonthKey",
                "OrganisationKey",
                "WorkforceFTE",
                "EstimatedAvailableFTE",
                "SicknessAbsenceRate",
                "TotalAttendances",
                "FourHourPerformanceRate"
            }
        ),
        {
            {"MonthKey", "_PreviousMonthKey"},
            {"WorkforceFTE", "PreviousWorkforceFTE"},
            {"EstimatedAvailableFTE", "PreviousEstimatedAvailableFTE"},
            {"SicknessAbsenceRate", "PreviousSicknessAbsenceRate"},
            {"TotalAttendances", "PreviousTotalAttendances"},
            {"FourHourPerformanceRate", "PreviousFourHourPerformanceRate"}
        }
    ),
    JoinPreviousMonth = Table.NestedJoin(
        AddPreviousMonthKey,
        {"_PreviousMonthKey", "OrganisationKey"},
        PreviousLookup,
        {"_PreviousMonthKey", "OrganisationKey"},
        "_Previous",
        JoinKind.LeftOuter
    ),
    ExpandPreviousMonth = Table.ExpandTableColumn(
        JoinPreviousMonth,
        "_Previous",
        {
            "PreviousWorkforceFTE",
            "PreviousEstimatedAvailableFTE",
            "PreviousSicknessAbsenceRate",
            "PreviousTotalAttendances",
            "PreviousFourHourPerformanceRate"
        },
        {
            "PreviousWorkforceFTE",
            "PreviousEstimatedAvailableFTE",
            "PreviousSicknessAbsenceRate",
            "PreviousTotalAttendances",
            "PreviousFourHourPerformanceRate"
        }
    ),
    AddWorkforceFTEChange = Table.AddColumn(
        ExpandPreviousMonth,
        "WorkforceFTEChange",
        each
            if [PreviousWorkforceFTE] = null or [WorkforceFTE] = null then
                null
            else
                [WorkforceFTE] - [PreviousWorkforceFTE],
        type nullable number
    ),
    AddAvailableFTEChange = Table.AddColumn(
        AddWorkforceFTEChange,
        "EstimatedAvailableFTEChange",
        each
            if [PreviousEstimatedAvailableFTE] = null
                or [EstimatedAvailableFTE] = null then
                null
            else
                [EstimatedAvailableFTE] - [PreviousEstimatedAvailableFTE],
        type nullable number
    ),
    AddAbsenceRateChange = Table.AddColumn(
        AddAvailableFTEChange,
        "SicknessAbsenceRateChange",
        each
            if [PreviousSicknessAbsenceRate] = null
                or [SicknessAbsenceRate] = null then
                null
            else
                [SicknessAbsenceRate] - [PreviousSicknessAbsenceRate],
        type nullable number
    ),
    AddAttendanceGrowth = Table.AddColumn(
        AddAbsenceRateChange,
        "AttendanceGrowthRate",
        each
            if [PreviousTotalAttendances] = null
                or [PreviousTotalAttendances] = 0
                or [TotalAttendances] = null then
                null
            else
                [TotalAttendances] / [PreviousTotalAttendances] - 1,
        type nullable number
    ),
    AddFourHourPerformanceChange = Table.AddColumn(
        AddAttendanceGrowth,
        "FourHourPerformanceChange",
        each
            if [PreviousFourHourPerformanceRate] = null
                or [FourHourPerformanceRate] = null then
                null
            else
                [FourHourPerformanceRate] - [PreviousFourHourPerformanceRate],
        type nullable number
    ),
    RemoveHelper = Table.RemoveColumns(
        AddFourHourPerformanceChange,
        {"_PreviousMonthKey"}
    ),
    Sorted = Table.Sort(
        RemoveHelper,
        {
            {"MonthKey", Order.Ascending},
            {"OrganisationName", Order.Ascending}
        }
    )
in
    Sorted

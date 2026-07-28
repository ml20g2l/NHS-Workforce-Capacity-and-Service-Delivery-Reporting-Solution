let
    Source = Table.SelectRows(
        qryWorkforceClean,
        each
            [StaffGroupName] <> null
                and Text.Lower(Text.Trim([StaffGroupName])) = "total"
                and List.Contains({"FTE", "HC"}, [DataType])
    ),
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
    Selected = Table.SelectColumns(
        AddOrganisationKey,
        {
            "MonthKey",
            "ReportingMonth",
            "OrganisationKey",
            "DataType",
            "MeasureValue"
        }
    ),
    Grouped = Table.Group(
        Selected,
        {
            "MonthKey",
            "ReportingMonth",
            "OrganisationKey",
            "DataType"
        },
        {{"MeasureValue", each List.Sum([MeasureValue]), type nullable number}}
    ),
    Pivoted = Table.Pivot(
        Grouped,
        List.Sort(List.Distinct(Grouped[DataType])),
        "DataType",
        "MeasureValue",
        List.Sum
    ),
    AddMissingHC =
        if Table.HasColumns(Pivoted, "HC") then
            Pivoted
        else
            Table.AddColumn(Pivoted, "HC", each null, type nullable number),
    AddMissingFTE =
        if Table.HasColumns(AddMissingHC, "FTE") then
            AddMissingHC
        else
            Table.AddColumn(AddMissingHC, "FTE", each null, type nullable number),
    Renamed = Table.RenameColumns(
        AddMissingFTE,
        {
            {"HC", "WorkforceHeadcount"},
            {"FTE", "WorkforceFTE"}
        }
    )
in
    Renamed

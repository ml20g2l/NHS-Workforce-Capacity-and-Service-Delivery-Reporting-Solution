let
    Source = Table.SelectRows(
        qryWorkforceClean,
        each
            [StaffGroupName] <> null
                and Text.Lower(Text.Trim([StaffGroupName])) <> "total"
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
    AddStaffGroupKey = Table.AddColumn(
        AddOrganisationKey,
        "StaffGroupKey",
        each Text.Upper(Text.Trim([StaffGroupName])),
        type text
    ),
    Selected = Table.SelectColumns(
        AddStaffGroupKey,
        {
            "MonthKey",
            "ReportingMonth",
            "OrganisationKey",
            "StaffGroupKey",
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
            "StaffGroupKey",
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
    RenameHeadcount = Table.RenameColumns(
        AddMissingFTE,
        {{"HC", "Headcount"}}
    ),
    JoinStaffGroup = Table.NestedJoin(
        RenameHeadcount,
        {"StaffGroupKey"},
        dimStaffGroup,
        {"StaffGroupKey"},
        "_StaffGroup",
        JoinKind.LeftOuter
    ),
    ExpandStaffGroup = Table.ExpandTableColumn(
        JoinStaffGroup,
        "_StaffGroup",
        {"StaffGroupName", "StaffGroupSortOrder"},
        {"StaffGroupName", "StaffGroupSortOrder"}
    ),
    Reordered = Table.ReorderColumns(
        ExpandStaffGroup,
        {
            "MonthKey",
            "ReportingMonth",
            "OrganisationKey",
            "StaffGroupKey",
            "StaffGroupName",
            "StaffGroupSortOrder",
            "Headcount",
            "FTE"
        }
    )
in
    Reordered

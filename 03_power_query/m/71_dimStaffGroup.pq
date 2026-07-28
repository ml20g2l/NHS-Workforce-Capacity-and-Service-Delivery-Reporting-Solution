let
    Source = Table.SelectRows(
        qryWorkforceClean,
        each
            [StaffGroupName] <> null
                and Text.Lower(Text.Trim([StaffGroupName])) <> "total"
    ),
    Selected = Table.SelectColumns(
        Source,
        {"StaffGroupName", "StaffGroupSortOrder"}
    ),
    AddStaffGroupKey = Table.AddColumn(
        Selected,
        "StaffGroupKey",
        each Text.Upper(Text.Trim([StaffGroupName])),
        type text
    ),
    AddNumericSortOrder = Table.AddColumn(
        AddStaffGroupKey,
        "_NumericSortOrder",
        each try Int64.From(Number.FromText([StaffGroupSortOrder])) otherwise null,
        Int64.Type
    ),
    Grouped = Table.Group(
        AddNumericSortOrder,
        {"StaffGroupKey"},
        {
            {
                "StaffGroupName",
                each List.First(List.Sort(List.Distinct([StaffGroupName]))),
                type text
            },
            {
                "StaffGroupSortOrder",
                each
                    let
                        SortValues = List.RemoveNulls([_NumericSortOrder])
                    in
                        if List.Count(SortValues) = 0 then
                            null
                        else
                            List.Min(SortValues),
                type nullable number
            }
        }
    ),
    Sorted = Table.Sort(
        Grouped,
        {
            {"StaffGroupSortOrder", Order.Ascending},
            {"StaffGroupName", Order.Ascending}
        }
    )
in
    Sorted

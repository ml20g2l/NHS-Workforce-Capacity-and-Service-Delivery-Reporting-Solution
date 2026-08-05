let
    Source = FactWorkforce,
    ReportingStaffGroupSortOrders = {2, 19, 23, 28},
    KeepAdditiveReportingGroups = Table.SelectRows(
        Source,
        each List.Contains(
            ReportingStaffGroupSortOrders,
            [StaffGroupSortOrder]
        )
    ),
    AddStaffGroupReportingScope = Table.AddColumn(
        KeepAdditiveReportingGroups,
        "StaffGroupReportingScope",
        each "Top-level additive reporting group",
        type text
    ),
    Reordered = Table.ReorderColumns(
        AddStaffGroupReportingScope,
        {
            "MonthKey",
            "ReportingMonth",
            "OrganisationKey",
            "StaffGroupKey",
            "StaffGroupName",
            "StaffGroupSortOrder",
            "StaffGroupReportingScope",
            "Headcount",
            "FTE"
        }
    )
in
    Reordered

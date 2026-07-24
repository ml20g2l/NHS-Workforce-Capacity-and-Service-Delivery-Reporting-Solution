let
    CommonColumns = {
        "SourceFile",
        "SourceDataset",
        "ReportingMonth",
        "LoadTimestamp",
        "RecordStatus"
    },
    WorkforceRows = Table.SelectColumns(
        dqWorkforceClassified,
        CommonColumns,
        MissingField.UseNull
    ),
    AbsenceRows = Table.SelectColumns(
        dqAbsenceClassified,
        CommonColumns,
        MissingField.UseNull
    ),
    ActivityRows = Table.SelectColumns(
        dqServiceActivityClassified,
        CommonColumns,
        MissingField.UseNull
    ),
    Combined = Table.Combine({
        WorkforceRows,
        AbsenceRows,
        ActivityRows
    }),
    Summary = Table.Group(
        Combined,
        {"SourceDataset", "SourceFile", "ReportingMonth", "LoadTimestamp", "RecordStatus"},
        {{"RowCount", each Table.RowCount(_), Int64.Type}}
    ),
    Sorted = Table.Sort(
        Summary,
        {
            {"SourceDataset", Order.Ascending},
            {"SourceFile", Order.Ascending},
            {"RecordStatus", Order.Ascending}
        }
    )
in
    Sorted

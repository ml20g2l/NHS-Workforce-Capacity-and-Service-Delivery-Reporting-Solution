let
    Workforce = Table.SelectColumns(
        dqWorkforceClassified,
        {"SourceDataset", "SourceFile", "ReportingMonth", "RecordStatus"}
    ),
    Absence = Table.SelectColumns(
        dqAbsenceClassified,
        {"SourceDataset", "SourceFile", "ReportingMonth", "RecordStatus"}
    ),
    Activity = Table.SelectColumns(
        dqServiceActivityClassified,
        {"SourceDataset", "SourceFile", "ReportingMonth", "RecordStatus"}
    ),
    Combined = Table.Combine({Workforce, Absence, Activity}),
    Summary = Table.Group(
        Combined,
        {"SourceDataset", "SourceFile", "ReportingMonth", "RecordStatus"},
        {{"RecordCount", each Table.RowCount(_), Int64.Type}}
    ),
    Sorted = Table.Sort(
        Summary,
        {
            {"SourceDataset", Order.Ascending},
            {"ReportingMonth", Order.Ascending},
            {"SourceFile", Order.Ascending},
            {"RecordStatus", Order.Ascending}
        }
    )
in
    Sorted

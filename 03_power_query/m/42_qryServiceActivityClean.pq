let
    Source = dqServiceActivityClassified,
    KeepReportableRows = Table.SelectRows(
        Source,
        each [RecordStatus] = "Accepted"
    )
in
    KeepReportableRows

let
    Source = dqWorkforceClassified,
    KeepReportableRows = Table.SelectRows(
        Source,
        each [RecordStatus] = "Accepted"
    )
in
    KeepReportableRows

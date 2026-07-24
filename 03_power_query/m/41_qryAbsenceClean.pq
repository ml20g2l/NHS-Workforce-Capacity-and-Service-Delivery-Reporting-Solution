let
    Source = dqAbsenceClassified,
    KeepReportableRows = Table.SelectRows(
        Source,
        each [RecordStatus] = "Accepted"
    )
in
    KeepReportableRows

let
    Source = dqAbsenceClassified,
    KeepReportableRows = Table.SelectRows(
        Source,
        each [RecordStatus] = "Accepted"
            and [InclusionFlag] = true
    )
in
    KeepReportableRows

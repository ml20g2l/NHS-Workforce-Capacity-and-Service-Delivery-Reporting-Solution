let
    CommonColumns = {
        "SourceFile",
        "SourceDataset",
        "ReportingMonth",
        "OrganisationCode",
        "CanonicalOrganisationName",
        "InclusionFlag",
        "ReportingCohort",
        "OrganisationMappingStatus",
        "SourceModifiedTimestamp",
        "SourceSizeBytes",
        "FileVersionRank",
        "FileDisposition",
        "LoadTimestamp",
        "RecordStatus",
        "ValidationReason"
    },
    WorkforceExceptions = Table.SelectColumns(
        Table.SelectRows(
            dqWorkforceClassified,
            each [RecordStatus] <> "Accepted"
        ),
        CommonColumns,
        MissingField.UseNull
    ),
    AbsenceExceptions = Table.SelectColumns(
        Table.SelectRows(
            dqAbsenceClassified,
            each [RecordStatus] <> "Accepted"
        ),
        CommonColumns,
        MissingField.UseNull
    ),
    ActivityExceptions = Table.SelectColumns(
        Table.SelectRows(
            dqServiceActivityClassified,
            each [RecordStatus] <> "Accepted"
        ),
        CommonColumns,
        MissingField.UseNull
    ),
    Combined = Table.Combine({
        WorkforceExceptions,
        AbsenceExceptions,
        ActivityExceptions
    })
in
    Combined

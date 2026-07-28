let
    LoadTimestamp = DateTimeZone.FixedUtcNow(),
    FileRegister = fnGetSourceFiles(
        pAbsenceFolder,
        "NHS Sickness Absence Rates"
    ),
    ActiveFiles = Table.SelectRows(
        FileRegister,
        each [FileDisposition] = "Active"
    ),
    AddTransformedData = Table.AddColumn(
        ActiveFiles,
        "TransformedData",
        (fileRow as record) =>
            let
                Transformed = fnTransformAbsenceFile(
                    fileRow[Content],
                    fileRow[SourceFile],
                    LoadTimestamp
                ),
                AddSourceModifiedTimestamp = Table.AddColumn(
                    Transformed,
                    "SourceModifiedTimestamp",
                    each
                        if fileRow[SourceModifiedTimestamp] = null then
                            null
                        else
                            DateTime.From(fileRow[SourceModifiedTimestamp]),
                    type nullable datetime
                ),
                AddSourceSizeBytes = Table.AddColumn(
                    AddSourceModifiedTimestamp,
                    "SourceSizeBytes",
                    each fileRow[SourceSizeBytes],
                    Int64.Type
                ),
                AddFileVersionRank = Table.AddColumn(
                    AddSourceSizeBytes,
                    "FileVersionRank",
                    each fileRow[FileVersionRank],
                    Int64.Type
                ),
                AddFileDisposition = Table.AddColumn(
                    AddFileVersionRank,
                    "FileDisposition",
                    each fileRow[FileDisposition],
                    type text
                )
            in
                AddFileDisposition,
        type table
    ),
    Combined =
        if Table.RowCount(AddTransformedData) = 0 then
            #table(
                {
                    "SourceDate",
                    "ReportingMonth",
                    "FileReportingMonth",
                    "RegionCode",
                    "RegionName",
                    "ICSCode",
                    "ICSName",
                    "OrganisationCode",
                    "OrganisationName",
                    "OrganisationType",
                    "FTEDaysLost",
                    "FTEDaysAvailable",
                    "SicknessAbsenceRatePercent",
                    "RecalculatedAbsenceRatePercent",
                    "AbsenceRateVariance",
                    "SourceFile",
                    "SourceDataset",
                    "SourceModifiedTimestamp",
                    "SourceSizeBytes",
                    "FileVersionRank",
                    "FileDisposition",
                    "LoadTimestamp",
                    "RecordStatus",
                    "ValidationReason"
                },
                {}
            )
        else
            Table.Combine(AddTransformedData[TransformedData])
in
    Combined

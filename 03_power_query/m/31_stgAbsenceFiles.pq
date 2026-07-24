let
    LoadTimestamp = DateTimeZone.FixedUtcNow(),
    FolderSource = Folder.Files(pAbsenceFolder),
    VisibleFiles = Table.SelectRows(
        FolderSource,
        each [Attributes]?[Hidden]? <> true
            and [Attributes]?[System]? <> true
            and not Text.StartsWith([Name], "~$")
    ),
    CSVFiles = Table.SelectRows(
        VisibleFiles,
        each Text.Lower([Extension]) = ".csv"
    ),
    AddTransformedData = Table.AddColumn(
        CSVFiles,
        "TransformedData",
        each fnTransformAbsenceFile([Content], [Name], LoadTimestamp),
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

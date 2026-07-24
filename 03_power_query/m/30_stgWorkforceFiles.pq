let
    LoadTimestamp = DateTimeZone.FixedUtcNow(),
    FolderSource = Folder.Files(pWorkforceFolder),
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
        each fnTransformWorkforceFile([Content], [Name], LoadTimestamp),
        type table
    ),
    Combined =
        if Table.RowCount(AddTransformedData) = 0 then
            #table(
                {
                    "SourceDate",
                    "ReportingMonth",
                    "RegionCode",
                    "RegionName",
                    "ICSCode",
                    "ICSName",
                    "OrganisationCode",
                    "OrganisationName",
                    "ClusterGroup",
                    "BenchmarkGroup",
                    "StaffGroupSortOrder",
                    "StaffGroupName",
                    "DataType",
                    "MeasureValue",
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

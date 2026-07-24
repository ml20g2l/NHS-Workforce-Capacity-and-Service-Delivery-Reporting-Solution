(folderPath as text, sourceDataset as text) as table =>
let
    FolderSource = Folder.Files(folderPath),
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
    KeepMetadata = Table.SelectColumns(
        CSVFiles,
        {"Content", "Name", "Extension", "Date modified", "Size", "Folder Path"}
    ),
    RenameMetadata = Table.RenameColumns(
        KeepMetadata,
        {
            {"Name", "SourceFile"},
            {"Date modified", "SourceModifiedTimestamp"},
            {"Size", "SourceSizeBytes"},
            {"Folder Path", "SourceFolder"}
        }
    ),
    AddDataset = Table.AddColumn(
        RenameMetadata,
        "SourceDataset",
        each sourceDataset,
        type text
    ),
    AddFileReportingMonth = Table.AddColumn(
        AddDataset,
        "FileReportingMonth",
        each fnMonthFromFileName([SourceFile]),
        type nullable date
    ),
    AddVersionGroupKey = Table.AddColumn(
        AddFileReportingMonth,
        "_VersionGroupKey",
        each
            if [FileReportingMonth] = null then
                "INVALID|" & [SourceFile]
            else
                Date.ToText([FileReportingMonth], "yyyy-MM"),
        type text
    ),
    VersionGroups = Table.Group(
        AddVersionGroupKey,
        {"SourceDataset", "_VersionGroupKey"},
        {
            {
                "_Files",
                (groupRows as table) =>
                    let
                        Sorted = Table.Sort(
                            groupRows,
                            {
                                {"SourceModifiedTimestamp", Order.Descending},
                                {"SourceFile", Order.Descending}
                            }
                        ),
                        Buffered = Table.Buffer(Sorted),
                        AddRank = Table.AddIndexColumn(
                            Buffered,
                            "FileVersionRank",
                            1,
                            1,
                            Int64.Type
                        ),
                        AddGroupCount = Table.AddColumn(
                            AddRank,
                            "FileGroupCount",
                            each Table.RowCount(Buffered),
                            Int64.Type
                        ),
                        AddDuplicateContentFlag = Table.AddColumn(
                            AddGroupCount,
                            "HasDuplicateContentInGroup",
                            each
                                let
                                    CurrentContent = [Content],
                                    MatchingFiles = Table.SelectRows(
                                        Buffered,
                                        each [Content] = CurrentContent
                                    )
                                in
                                    Table.RowCount(MatchingFiles) > 1,
                            type logical
                        ),
                        AddDisposition = Table.AddColumn(
                            AddDuplicateContentFlag,
                            "FileDisposition",
                            each
                                if [FileReportingMonth] = null then
                                    "Invalid filename"
                                else if [FileVersionRank] = 1 then
                                    "Active"
                                else if [HasDuplicateContentInGroup] then
                                    "Duplicate - superseded"
                                else
                                    "Revised - superseded",
                            type text
                        ),
                        AddSelectionReason = Table.AddColumn(
                            AddDisposition,
                            "FileSelectionReason",
                            each
                                if [FileReportingMonth] = null then
                                    "No YYYY-MM token was found in the filename"
                                else if [FileVersionRank] = 1 and [FileGroupCount] = 1 then
                                    "Only file received for reporting month"
                                else if [FileVersionRank] = 1 then
                                    "Latest modified file selected for reporting month"
                                else if [HasDuplicateContentInGroup] then
                                    "Content matches another file received for the reporting month"
                                else
                                    "Older non-identical file retained as a superseded revision",
                            type text
                        )
                    in
                        AddSelectionReason,
                type table
            }
        }
    ),
    Combined =
        if Table.RowCount(VersionGroups) = 0 then
            #table(
                {
                    "Content",
                    "SourceFile",
                    "Extension",
                    "SourceModifiedTimestamp",
                    "SourceSizeBytes",
                    "SourceFolder",
                    "SourceDataset",
                    "FileReportingMonth",
                    "FileVersionRank",
                    "FileGroupCount",
                    "HasDuplicateContentInGroup",
                    "FileDisposition",
                    "FileSelectionReason"
                },
                {}
            )
        else
            Table.Combine(VersionGroups[_Files]),
    RemoveGroupKey = Table.RemoveColumns(
        Combined,
        {"_VersionGroupKey"},
        MissingField.Ignore
    )
in
    RemoveGroupKey

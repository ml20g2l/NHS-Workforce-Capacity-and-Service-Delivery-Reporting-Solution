(fileContent as binary, sourceFile as text, loadTimestamp as datetimezone) as table =>
let
    ExpectedColumns = {
        "Date",
        "NHSE_Region_Code",
        "NHSE_Region_Name",
        "ICS code",
        "ICS name",
        "Org Code",
        "Org Name",
        "Cluster Group",
        "Benchmark Group",
        "Staff Group Sort Order",
        "Staff Group",
        "Data Type",
        "Total"
    },
    Raw = Csv.Document(
        fileContent,
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Promoted = Table.PromoteHeaders(Raw, [PromoteAllScalars = true]),
    CleanHeaders = Table.TransformColumnNames(
        Promoted,
        each Text.Trim(Text.Clean(Text.From(_)))
    ),
    ActualColumns = Table.ColumnNames(CleanHeaders),
    MissingColumns = List.Difference(ExpectedColumns, ActualColumns),
    UnexpectedColumns = List.Difference(ActualColumns, ExpectedColumns),
    AddMissingColumns = List.Accumulate(
        MissingColumns,
        CleanHeaders,
        (state as table, columnName as text) =>
            Table.AddColumn(state, columnName, each null)
    ),
    Selected = Table.SelectColumns(
        AddMissingColumns,
        ExpectedColumns,
        MissingField.UseNull
    ),
    Renamed = Table.RenameColumns(
        Selected,
        {
            {"Date", "SourceDate"},
            {"NHSE_Region_Code", "RegionCode"},
            {"NHSE_Region_Name", "RegionName"},
            {"ICS code", "ICSCode"},
            {"ICS name", "ICSName"},
            {"Org Code", "OrganisationCode"},
            {"Org Name", "OrganisationName"},
            {"Cluster Group", "ClusterGroup"},
            {"Benchmark Group", "BenchmarkGroup"},
            {"Staff Group Sort Order", "StaffGroupSortOrder"},
            {"Staff Group", "StaffGroupName"},
            {"Data Type", "DataType"},
            {"Total", "MeasureValue"}
        }
    ),
    Standardised = Table.TransformColumns(
        Renamed,
        {
            {"SourceDate", each fnParseDate(_), type nullable date},
            {"RegionCode", each if _ = null then null else Text.Trim(Text.From(_)), type nullable text},
            {"RegionName", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"ICSCode", each if _ = null then null else Text.Trim(Text.From(_)), type nullable text},
            {"ICSName", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"OrganisationCode", each fnCleanOrganisationCode(_), type nullable text},
            {"OrganisationName", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"ClusterGroup", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"BenchmarkGroup", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"StaffGroupSortOrder", each if _ = null then null else Text.Trim(Text.From(_)), type nullable text},
            {"StaffGroupName", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"DataType", each if _ = null then null else Text.Upper(Text.Trim(Text.From(_))), type nullable text},
            {"MeasureValue", each fnParseNumber(_), type nullable number}
        }
    ),
    KeepRelevantWindow = Table.SelectRows(
        Standardised,
        each
            [SourceDate] = null
            or (
                Date.StartOfMonth([SourceDate]) >= pReportingStartMonth
                and Date.StartOfMonth([SourceDate]) <= pReportingEndMonth
            )
    ),
    AddReportingMonth = Table.AddColumn(
        KeepRelevantWindow,
        "ReportingMonth",
        each if [SourceDate] = null then null else Date.StartOfMonth([SourceDate]),
        type nullable date
    ),
    AddSourceFile = Table.AddColumn(
        AddReportingMonth,
        "SourceFile",
        each sourceFile,
        type text
    ),
    AddSourceDataset = Table.AddColumn(
        AddSourceFile,
        "SourceDataset",
        each "NHS Workforce Statistics",
        type text
    ),
    AddLoadTimestamp = Table.AddColumn(
        AddSourceDataset,
        "LoadTimestamp",
        each DateTimeZone.RemoveZone(loadTimestamp),
        type datetime
    ),
    AddValidationReason = Table.AddColumn(
        AddLoadTimestamp,
        "ValidationReason",
        each Text.Combine(
            List.RemoveNulls({
                if List.Count(MissingColumns) > 0 then
                    "Missing required columns: " & Text.Combine(MissingColumns, ", ")
                else
                    null,
                if [ReportingMonth] = null then "Invalid SourceDate" else null,
                if [OrganisationCode] = null then "Missing OrganisationCode" else null,
                if [StaffGroupName] = null or [StaffGroupName] = "" then "Missing StaffGroupName" else null,
                if [DataType] = null or not List.Contains({"FTE", "HC"}, [DataType]) then
                    "Invalid DataType"
                else
                    null,
                if [MeasureValue] = null then "Invalid MeasureValue" else null,
                if [MeasureValue] <> null and [MeasureValue] < 0 then "Negative MeasureValue" else null,
                if List.Count(UnexpectedColumns) > 0 then
                    "Unexpected columns ignored: " & Text.Combine(UnexpectedColumns, ", ")
                else
                    null
            }),
            "; "
        ),
        type text
    ),
    AddRecordStatus = Table.AddColumn(
        AddValidationReason,
        "RecordStatus",
        each
            if List.Count(MissingColumns) > 0 then
                "Rejected"
            else if [ReportingMonth] = null
                or [OrganisationCode] = null
                or [StaffGroupName] = null
                or [StaffGroupName] = ""
                or [DataType] = null
                or not List.Contains({"FTE", "HC"}, [DataType])
                or [MeasureValue] = null
                or [MeasureValue] < 0 then
                "Rejected"
            else if List.Count(UnexpectedColumns) > 0 then
                "Review Required"
            else
                "Accepted",
        type text
    ),
    Reordered = Table.ReorderColumns(
        AddRecordStatus,
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
        }
    )
in
    Reordered

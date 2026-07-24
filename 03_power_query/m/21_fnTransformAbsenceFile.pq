(fileContent as binary, sourceFile as text, loadTimestamp as datetimezone) as table =>
let
    ExpectedColumns = {
        "DATE",
        "NHSE_REGION_CODE",
        "NHSE_REGION_NAME",
        "ICS_CODE",
        "ICS_NAME",
        "ORG_CODE",
        "ORG_NAME",
        "ORG_TYPE",
        "FTE_DAYS_LOST",
        "FTE_DAYS_AVAILABLE",
        "SICKNESS_ABSENCE_RATE_PERCENT"
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
            {"DATE", "SourceDate"},
            {"NHSE_REGION_CODE", "RegionCode"},
            {"NHSE_REGION_NAME", "RegionName"},
            {"ICS_CODE", "ICSCode"},
            {"ICS_NAME", "ICSName"},
            {"ORG_CODE", "OrganisationCode"},
            {"ORG_NAME", "OrganisationName"},
            {"ORG_TYPE", "OrganisationType"},
            {"FTE_DAYS_LOST", "FTEDaysLost"},
            {"FTE_DAYS_AVAILABLE", "FTEDaysAvailable"},
            {"SICKNESS_ABSENCE_RATE_PERCENT", "SicknessAbsenceRatePercent"}
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
            {"OrganisationType", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"FTEDaysLost", each fnParseNumber(_), type nullable number},
            {"FTEDaysAvailable", each fnParseNumber(_), type nullable number},
            {"SicknessAbsenceRatePercent", each fnParseNumber(_), type nullable number}
        }
    ),
    AddReportingMonth = Table.AddColumn(
        Standardised,
        "ReportingMonth",
        each if [SourceDate] = null then null else Date.StartOfMonth([SourceDate]),
        type nullable date
    ),
    AddFileReportingMonth = Table.AddColumn(
        AddReportingMonth,
        "FileReportingMonth",
        each fnMonthFromFileName(sourceFile),
        type nullable date
    ),
    AddRecalculatedRate = Table.AddColumn(
        AddFileReportingMonth,
        "RecalculatedAbsenceRatePercent",
        each
            if [FTEDaysAvailable] = null or [FTEDaysAvailable] = 0 then
                null
            else
                [FTEDaysLost] / [FTEDaysAvailable] * 100,
        type nullable number
    ),
    AddRateVariance = Table.AddColumn(
        AddRecalculatedRate,
        "AbsenceRateVariance",
        each
            if [SicknessAbsenceRatePercent] = null
                or [RecalculatedAbsenceRatePercent] = null then
                null
            else
                [SicknessAbsenceRatePercent] - [RecalculatedAbsenceRatePercent],
        type nullable number
    ),
    AddSourceFile = Table.AddColumn(
        AddRateVariance,
        "SourceFile",
        each sourceFile,
        type text
    ),
    AddSourceDataset = Table.AddColumn(
        AddSourceFile,
        "SourceDataset",
        each "NHS Sickness Absence Rates",
        type text
    ),
    AddLoadTimestamp = Table.AddColumn(
        AddSourceDataset,
        "LoadTimestamp",
        each loadTimestamp,
        type datetimezone
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
                if [FileReportingMonth] = null then "Reporting month missing from filename" else null,
                if [ReportingMonth] <> null
                    and ([ReportingMonth] < pReportingStartMonth
                        or [ReportingMonth] > pReportingEndMonth) then
                    "Outside reporting window"
                else
                    null,
                if [OrganisationCode] = null then "Missing OrganisationCode" else null,
                if [FTEDaysLost] = null then "Invalid FTEDaysLost" else null,
                if [FTEDaysAvailable] = null then "Invalid FTEDaysAvailable" else null,
                if [SicknessAbsenceRatePercent] = null then "Invalid SicknessAbsenceRatePercent" else null,
                if [FTEDaysLost] <> null and [FTEDaysLost] < 0 then "Negative FTEDaysLost" else null,
                if [FTEDaysAvailable] <> null and [FTEDaysAvailable] < 0 then "Negative FTEDaysAvailable" else null,
                if [SicknessAbsenceRatePercent] <> null
                    and ([SicknessAbsenceRatePercent] < 0
                        or [SicknessAbsenceRatePercent] > 100) then
                    "SicknessAbsenceRatePercent outside 0-100"
                else
                    null,
                if [ReportingMonth] <> null
                    and [FileReportingMonth] <> null
                    and [ReportingMonth] <> [FileReportingMonth] then
                    "Row month does not match filename month"
                else
                    null,
                if [AbsenceRateVariance] <> null
                    and Number.Abs([AbsenceRateVariance]) > 0.02 then
                    "Published absence rate differs from recalculated rate by more than 0.02 percentage points"
                else
                    null,
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
            else if [ReportingMonth] <> null
                and ([ReportingMonth] < pReportingStartMonth
                    or [ReportingMonth] > pReportingEndMonth) then
                "Rejected"
            else if [ReportingMonth] = null
                or [OrganisationCode] = null
                or [FTEDaysLost] = null
                or [FTEDaysAvailable] = null
                or [SicknessAbsenceRatePercent] = null
                or [FTEDaysLost] < 0
                or [FTEDaysAvailable] < 0
                or [SicknessAbsenceRatePercent] < 0
                or [SicknessAbsenceRatePercent] > 100 then
                "Rejected"
            else if [FileReportingMonth] = null
                or [ReportingMonth] <> [FileReportingMonth]
                or ([AbsenceRateVariance] <> null
                    and Number.Abs([AbsenceRateVariance]) > 0.02)
                or List.Count(UnexpectedColumns) > 0 then
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
        }
    )
in
    Reordered

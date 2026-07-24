(fileContent as binary, sourceFile as text, loadTimestamp as datetimezone) as table =>
let
    ExpectedColumns = {
        "Period",
        "Org Code",
        "Parent Org",
        "Org name",
        "A&E attendances Type 1",
        "A&E attendances Type 2",
        "A&E attendances Other A&E Department",
        "A&E attendances Booked Appointments Type 1",
        "A&E attendances Booked Appointments Type 2",
        "A&E attendances Booked Appointments Other Department",
        "Attendances over 4hrs Type 1",
        "Attendances over 4hrs Type 2",
        "Attendances over 4hrs Other Department",
        "Attendances over 4hrs Booked Appointments Type 1",
        "Attendances over 4hrs Booked Appointments Type 2",
        "Attendances over 4hrs Booked Appointments Other Department",
        "Patients who have waited 4-12 hs from DTA to admission",
        "Patients who have waited 12+ hrs from DTA to admission",
        "Emergency admissions via A&E - Type 1",
        "Emergency admissions via A&E - Type 2",
        "Emergency admissions via A&E - Other A&E department",
        "Other emergency admissions"
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
            {"Period", "SourcePeriod"},
            {"Org Code", "OrganisationCode"},
            {"Parent Org", "ParentOrganisationCode"},
            {"Org name", "OrganisationName"},
            {"A&E attendances Type 1", "AttendancesType1"},
            {"A&E attendances Type 2", "AttendancesType2"},
            {"A&E attendances Other A&E Department", "AttendancesOther"},
            {"A&E attendances Booked Appointments Type 1", "BookedAttendancesType1"},
            {"A&E attendances Booked Appointments Type 2", "BookedAttendancesType2"},
            {"A&E attendances Booked Appointments Other Department", "BookedAttendancesOther"},
            {"Attendances over 4hrs Type 1", "Over4HoursType1"},
            {"Attendances over 4hrs Type 2", "Over4HoursType2"},
            {"Attendances over 4hrs Other Department", "Over4HoursOther"},
            {"Attendances over 4hrs Booked Appointments Type 1", "BookedOver4HoursType1"},
            {"Attendances over 4hrs Booked Appointments Type 2", "BookedOver4HoursType2"},
            {"Attendances over 4hrs Booked Appointments Other Department", "BookedOver4HoursOther"},
            {"Patients who have waited 4-12 hs from DTA to admission", "Waits4To12HoursDTA"},
            {"Patients who have waited 12+ hrs from DTA to admission", "Waits12PlusHoursDTA"},
            {"Emergency admissions via A&E - Type 1", "EmergencyAdmissionsViaAEType1"},
            {"Emergency admissions via A&E - Type 2", "EmergencyAdmissionsViaAEType2"},
            {"Emergency admissions via A&E - Other A&E department", "EmergencyAdmissionsViaAEOther"},
            {"Other emergency admissions", "OtherEmergencyAdmissions"}
        }
    ),
    ActivityMeasureColumns = {
        "AttendancesType1",
        "AttendancesType2",
        "AttendancesOther",
        "BookedAttendancesType1",
        "BookedAttendancesType2",
        "BookedAttendancesOther",
        "Over4HoursType1",
        "Over4HoursType2",
        "Over4HoursOther",
        "BookedOver4HoursType1",
        "BookedOver4HoursType2",
        "BookedOver4HoursOther",
        "Waits4To12HoursDTA",
        "Waits12PlusHoursDTA",
        "EmergencyAdmissionsViaAEType1",
        "EmergencyAdmissionsViaAEType2",
        "EmergencyAdmissionsViaAEOther",
        "OtherEmergencyAdmissions"
    },
    TextStandardised = Table.TransformColumns(
        Renamed,
        {
            {"SourcePeriod", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"OrganisationCode", each fnCleanOrganisationCode(_), type nullable text},
            {"ParentOrganisationCode", each fnCleanOrganisationCode(_), type nullable text},
            {"OrganisationName", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text}
        }
    ),
    MeasuresStandardised = Table.TransformColumns(
        TextStandardised,
        List.Transform(
            ActivityMeasureColumns,
            (columnName as text) =>
                {
                    columnName,
                    (cellValue as any) => fnParseNumber(cellValue),
                    type nullable number
                }
        )
    ),
    AddReportingMonth = Table.AddColumn(
        MeasuresStandardised,
        "ReportingMonth",
        each fnMonthFromFileName(sourceFile),
        type nullable date
    ),
    AddPeriodReportingMonth = Table.AddColumn(
        AddReportingMonth,
        "PeriodReportingMonth",
        each fnMonthFromAEPeriod([SourcePeriod]),
        type nullable date
    ),
    AddInvalidMeasureList = Table.AddColumn(
        AddPeriodReportingMonth,
        "_InvalidMeasureColumns",
        (row as record) =>
            List.Select(
                ActivityMeasureColumns,
                (columnName as text) =>
                    let
                        MeasureValue = Record.Field(row, columnName)
                    in
                        MeasureValue = null or MeasureValue < 0
            ),
        type list
    ),
    AddSourceFile = Table.AddColumn(
        AddInvalidMeasureList,
        "SourceFile",
        each sourceFile,
        type text
    ),
    AddSourceDataset = Table.AddColumn(
        AddSourceFile,
        "SourceDataset",
        each "A&E Attendances and Emergency Admissions",
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
                if [ReportingMonth] = null then "Reporting month missing from filename" else null,
                if [ReportingMonth] <> null
                    and ([ReportingMonth] < pReportingStartMonth
                        or [ReportingMonth] > pReportingEndMonth) then
                    "Outside reporting window"
                else
                    null,
                if [SourcePeriod] = null or [SourcePeriod] = "" then "Missing SourcePeriod" else null,
                if [OrganisationCode] = null then "Missing OrganisationCode" else null,
                if [OrganisationCode] = "TOTAL" then "Published aggregate TOTAL row" else null,
                if [OrganisationCode] <> "TOTAL"
                    and [PeriodReportingMonth] = null then
                    "Invalid SourcePeriod"
                else
                    null,
                if [PeriodReportingMonth] <> null
                    and [ReportingMonth] <> null
                    and [PeriodReportingMonth] <> [ReportingMonth] then
                    "Row period does not match filename month"
                else
                    null,
                if [Over4HoursType1] <> null
                    and [AttendancesType1] <> null
                    and [Over4HoursType1] > [AttendancesType1] then
                    "Over4HoursType1 exceeds AttendancesType1"
                else
                    null,
                if [Over4HoursType2] <> null
                    and [AttendancesType2] <> null
                    and [Over4HoursType2] > [AttendancesType2] then
                    "Over4HoursType2 exceeds AttendancesType2"
                else
                    null,
                if [Over4HoursOther] <> null
                    and [AttendancesOther] <> null
                    and [Over4HoursOther] > [AttendancesOther] then
                    "Over4HoursOther exceeds AttendancesOther"
                else
                    null,
                if [BookedOver4HoursType1] <> null
                    and [BookedAttendancesType1] <> null
                    and [BookedOver4HoursType1] > [BookedAttendancesType1] then
                    "BookedOver4HoursType1 exceeds BookedAttendancesType1"
                else
                    null,
                if [BookedOver4HoursType2] <> null
                    and [BookedAttendancesType2] <> null
                    and [BookedOver4HoursType2] > [BookedAttendancesType2] then
                    "BookedOver4HoursType2 exceeds BookedAttendancesType2"
                else
                    null,
                if [BookedOver4HoursOther] <> null
                    and [BookedAttendancesOther] <> null
                    and [BookedOver4HoursOther] > [BookedAttendancesOther] then
                    "BookedOver4HoursOther exceeds BookedAttendancesOther"
                else
                    null,
                if List.Count([_InvalidMeasureColumns]) > 0 then
                    "Invalid or negative measures: "
                    & Text.Combine([_InvalidMeasureColumns], ", ")
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
            else if [OrganisationCode] = "TOTAL" then
                "Rejected"
            else if [ReportingMonth] = null
                or [SourcePeriod] = null
                or [SourcePeriod] = ""
                or [PeriodReportingMonth] = null
                or [OrganisationCode] = null
                or List.Count([_InvalidMeasureColumns]) > 0
                or [Over4HoursType1] > [AttendancesType1]
                or [Over4HoursType2] > [AttendancesType2]
                or [Over4HoursOther] > [AttendancesOther]
                or [BookedOver4HoursType1] > [BookedAttendancesType1]
                or [BookedOver4HoursType2] > [BookedAttendancesType2]
                or [BookedOver4HoursOther] > [BookedAttendancesOther] then
                "Rejected"
            else if [PeriodReportingMonth] <> [ReportingMonth]
                or List.Count(UnexpectedColumns) > 0 then
                "Review Required"
            else
                "Accepted",
        type text
    ),
    RemoveHelperColumn = Table.RemoveColumns(
        AddRecordStatus,
        {"_InvalidMeasureColumns"}
    ),
    Reordered = Table.ReorderColumns(
        RemoveHelperColumn,
        {
            "SourcePeriod",
            "ReportingMonth",
            "PeriodReportingMonth",
            "OrganisationCode",
            "ParentOrganisationCode",
            "OrganisationName",
            "AttendancesType1",
            "AttendancesType2",
            "AttendancesOther",
            "BookedAttendancesType1",
            "BookedAttendancesType2",
            "BookedAttendancesOther",
            "Over4HoursType1",
            "Over4HoursType2",
            "Over4HoursOther",
            "BookedOver4HoursType1",
            "BookedOver4HoursType2",
            "BookedOver4HoursOther",
            "Waits4To12HoursDTA",
            "Waits12PlusHoursDTA",
            "EmergencyAdmissionsViaAEType1",
            "EmergencyAdmissionsViaAEType2",
            "EmergencyAdmissionsViaAEOther",
            "OtherEmergencyAdmissions",
            "SourceFile",
            "SourceDataset",
            "LoadTimestamp",
            "RecordStatus",
            "ValidationReason"
        }
    )
in
    Reordered

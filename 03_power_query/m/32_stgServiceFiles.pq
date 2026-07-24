let
    LoadTimestamp = DateTimeZone.FixedUtcNow(),
    FileRegister = fnGetSourceFiles(
        pActivityFolder,
        "A&E Attendances and Emergency Admissions"
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
                Transformed = fnTransformActivityFile(
                    fileRow[Content],
                    fileRow[SourceFile],
                    LoadTimestamp
                ),
                AddSourceModifiedTimestamp = Table.AddColumn(
                    Transformed,
                    "SourceModifiedTimestamp",
                    each fileRow[SourceModifiedTimestamp],
                    type nullable datetimezone
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

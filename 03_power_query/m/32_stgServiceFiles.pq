let
    LoadTimestamp = DateTimeZone.FixedUtcNow(),
    FolderSource = Folder.Files(pActivityFolder),
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
        each fnTransformActivityFile([Content], [Name], LoadTimestamp),
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

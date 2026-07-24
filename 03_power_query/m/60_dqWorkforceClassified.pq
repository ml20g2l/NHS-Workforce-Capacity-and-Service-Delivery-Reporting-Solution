let
    Source = stgWorkforceFiles,
    PreserveBaseStatus = Table.RenameColumns(
        Source,
        {
            {"RecordStatus", "BaseRecordStatus"},
            {"ValidationReason", "BaseValidationReason"}
        }
    ),
    DuplicateCounts = Table.Group(
        PreserveBaseStatus,
        {"ReportingMonth", "OrganisationCode", "StaffGroupName", "DataType"},
        {{"DuplicateCount", each Table.RowCount(_), Int64.Type}}
    ),
    JoinDuplicateCounts = Table.NestedJoin(
        PreserveBaseStatus,
        {"ReportingMonth", "OrganisationCode", "StaffGroupName", "DataType"},
        DuplicateCounts,
        {"ReportingMonth", "OrganisationCode", "StaffGroupName", "DataType"},
        "_Duplicate",
        JoinKind.LeftOuter
    ),
    ExpandDuplicateCounts = Table.ExpandTableColumn(
        JoinDuplicateCounts,
        "_Duplicate",
        {"DuplicateCount"},
        {"DuplicateCount"}
    ),
    OrganisationNameCounts = Table.Group(
        Table.SelectRows(
            PreserveBaseStatus,
            each [OrganisationCode] <> null and [OrganisationName] <> null
        ),
        {"OrganisationCode"},
        {
            {
                "OrganisationNameVariantCount",
                each List.Count(List.Distinct([OrganisationName])),
                Int64.Type
            }
        }
    ),
    JoinOrganisationNames = Table.NestedJoin(
        ExpandDuplicateCounts,
        {"OrganisationCode"},
        OrganisationNameCounts,
        {"OrganisationCode"},
        "_OrganisationNames",
        JoinKind.LeftOuter
    ),
    ExpandOrganisationNames = Table.ExpandTableColumn(
        JoinOrganisationNames,
        "_OrganisationNames",
        {"OrganisationNameVariantCount"},
        {"OrganisationNameVariantCount"}
    ),
    FillOrganisationNameCount = Table.ReplaceValue(
        ExpandOrganisationNames,
        null,
        0,
        Replacer.ReplaceValue,
        {"OrganisationNameVariantCount"}
    ),
    AddRecordStatus = Table.AddColumn(
        FillOrganisationNameCount,
        "RecordStatus",
        each
            if [BaseRecordStatus] = "Rejected" then
                "Rejected"
            else if [DuplicateCount] > 1 then
                "Rejected"
            else if [BaseRecordStatus] = "Review Required"
                or [OrganisationNameVariantCount] > 1 then
                "Review Required"
            else
                "Accepted",
        type text
    ),
    AddValidationReason = Table.AddColumn(
        AddRecordStatus,
        "ValidationReason",
        each Text.Combine(
            List.RemoveNulls({
                if [BaseValidationReason] = null or [BaseValidationReason] = "" then
                    null
                else
                    [BaseValidationReason],
                if [DuplicateCount] > 1 then
                    "Duplicate Month-Organisation-StaffGroup-DataType key"
                else
                    null,
                if [OrganisationNameVariantCount] > 1 then
                    "Organisation code has multiple organisation names in reporting window"
                else
                    null
            }),
            "; "
        ),
        type text
    ),
    RemoveHelpers = Table.RemoveColumns(
        AddValidationReason,
        {
            "BaseRecordStatus",
            "BaseValidationReason",
            "DuplicateCount",
            "OrganisationNameVariantCount"
        }
    )
in
    RemoveHelpers

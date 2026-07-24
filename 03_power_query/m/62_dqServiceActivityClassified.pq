let
    Source = stgServiceFiles,
    PreserveBaseStatus = Table.RenameColumns(
        Source,
        {
            {"RecordStatus", "BaseRecordStatus"},
            {"ValidationReason", "BaseValidationReason"}
        }
    ),
    JoinOrganisationReference = Table.NestedJoin(
        PreserveBaseStatus,
        {"OrganisationCode"},
        dimOrganisation,
        {"OrganisationCode"},
        "_OrganisationReference",
        JoinKind.LeftOuter
    ),
    ReferenceApplied = Table.ExpandTableColumn(
        JoinOrganisationReference,
        "_OrganisationReference",
        {
            "CanonicalOrganisationName",
            "InclusionFlag",
            "ReportingCohort",
            "MappingStatus"
        },
        {
            "CanonicalOrganisationName",
            "InclusionFlag",
            "ReportingCohort",
            "OrganisationMappingStatus"
        }
    ),
    DuplicateCounts = Table.Group(
        ReferenceApplied,
        {"ReportingMonth", "OrganisationCode"},
        {{"DuplicateCount", each Table.RowCount(_), Int64.Type}}
    ),
    JoinDuplicateCounts = Table.NestedJoin(
        PreserveBaseStatus,
        {"ReportingMonth", "OrganisationCode"},
        DuplicateCounts,
        {"ReportingMonth", "OrganisationCode"},
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
            ReferenceApplied,
            each [OrganisationCode] <> null
                and [OrganisationCode] <> "TOTAL"
                and [OrganisationName] <> null
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
            else if [OrganisationMappingStatus] = null
                or [BaseRecordStatus] = "Review Required"
                or (
                    [OrganisationNameVariantCount] > 1
                        and [OrganisationMappingStatus] <> "Approved alias history"
                ) then
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
                    "Duplicate Month-Organisation activity key"
                else
                    null,
                if [OrganisationCode] <> "TOTAL"
                    and [OrganisationMappingStatus] = null then
                    "Organisation code not found in controlled stable reference"
                else
                    null,
                if [OrganisationNameVariantCount] > 1
                    and [OrganisationMappingStatus] <> null
                    and [OrganisationMappingStatus] <> "Approved alias history" then
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

let
    Source = Csv.Document(
        File.Contents(pReferenceFolder & "\dim_organisation.csv"),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    Selected = Table.SelectColumns(
        Promoted,
        {
            "OrganisationCode",
            "CanonicalOrganisationName",
            "OrganisationType",
            "RegionCode",
            "RegionName",
            "ICSCode",
            "ICSName",
            "ValidFromMonth",
            "ValidToMonth",
            "StableAllThreeMonths",
            "InclusionFlag",
            "ReportingCohort",
            "ObservedAliases",
            "MappingStatus",
            "ReviewNote"
        },
        MissingField.UseNull
    ),
    CleanText = Table.TransformColumns(
        Selected,
        {
            {"OrganisationCode", each fnCleanOrganisationCode(_), type nullable text},
            {"CanonicalOrganisationName", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"OrganisationType", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"RegionCode", each fnCleanOrganisationCode(_), type nullable text},
            {"RegionName", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"ICSCode", each fnCleanOrganisationCode(_), type nullable text},
            {"ICSName", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"ReportingCohort", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"ObservedAliases", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"MappingStatus", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text},
            {"ReviewNote", each if _ = null then null else Text.Trim(Text.Clean(Text.From(_))), type nullable text}
        }
    ),
    ParseDates = Table.TransformColumns(
        CleanText,
        {
            {"ValidFromMonth", each fnParseDate(_), type nullable date},
            {"ValidToMonth", each fnParseDate(_), type nullable date}
        }
    ),
    ParseFlags = Table.TransformColumns(
        ParseDates,
        {
            {"StableAllThreeMonths", each Text.Upper(Text.From(_)) = "TRUE", type logical},
            {"InclusionFlag", each Text.Upper(Text.From(_)) = "TRUE", type logical}
        }
    ),
    UniqueCodes = Table.Distinct(ParseFlags, {"OrganisationCode"})
in
    UniqueCodes

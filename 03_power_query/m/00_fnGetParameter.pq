(parameterName as text) as any =>
let
    ParameterTable = Excel.CurrentWorkbook(){[Name = "tblParameters"]}[Content],
    NormalisedNames = Table.TransformColumns(
        ParameterTable,
        {{"ParameterName", each Text.Trim(Text.From(_)), type text}}
    ),
    MatchingRows = Table.SelectRows(
        NormalisedNames,
        each [ParameterName] = parameterName
    ),
    MatchCount = Table.RowCount(MatchingRows),
    ParameterValue =
        if MatchCount <> 1 then
            error Error.Record(
                "ParameterError",
                "Expected exactly one parameter row.",
                [ParameterName = parameterName, MatchingRows = MatchCount]
            )
        else
            MatchingRows{0}[ParameterValue]
in
    ParameterValue

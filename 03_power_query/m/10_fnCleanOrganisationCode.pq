(value as any) as nullable text =>
let
    AsText =
        if value = null then
            null
        else
            Text.From(value),
    ReplaceNonBreakingSpace =
        if AsText = null then
            null
        else
            Text.Replace(AsText, Character.FromNumber(160), " "),
    Cleaned =
        if ReplaceNonBreakingSpace = null then
            null
        else
            Text.Upper(Text.Trim(Text.Clean(ReplaceNonBreakingSpace))),
    Result =
        if Cleaned = null or Cleaned = "" then
            null
        else
            Cleaned
in
    Result

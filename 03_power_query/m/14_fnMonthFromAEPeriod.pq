(sourcePeriod as nullable text) as nullable date =>
let
    CleanPeriod =
        if sourcePeriod = null then
            null
        else
            Text.Upper(Text.Trim(Text.Clean(sourcePeriod))),
    WithoutPrefix =
        if CleanPeriod <> null and Text.StartsWith(CleanPeriod, "MSITAE-") then
            Text.AfterDelimiter(CleanPeriod, "MSITAE-")
        else
            null,
    LastHyphen =
        if WithoutPrefix = null then
            -1
        else
            Text.PositionOf(WithoutPrefix, "-", Occurrence.Last),
    MonthName =
        if LastHyphen > 0 then
            Text.Start(WithoutPrefix, LastHyphen)
        else
            null,
    YearText =
        if LastHyphen > 0 then
            Text.Range(WithoutPrefix, LastHyphen + 1)
        else
            null,
    MonthNumber =
        if MonthName = null then
            null
        else
            List.PositionOf(
                {
                    "JANUARY",
                    "FEBRUARY",
                    "MARCH",
                    "APRIL",
                    "MAY",
                    "JUNE",
                    "JULY",
                    "AUGUST",
                    "SEPTEMBER",
                    "OCTOBER",
                    "NOVEMBER",
                    "DECEMBER"
                },
                MonthName
            ) + 1,
    YearNumber = try Number.FromText(YearText) otherwise null,
    Result =
        if MonthNumber < 1 or YearNumber = null then
            null
        else
            #date(YearNumber, MonthNumber, 1)
in
    Result

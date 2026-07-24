(fileName as text) as nullable date =>
let
    BaseName = Text.BeforeDelimiter(fileName, ".", {0, RelativePosition.FromEnd}),
    MonthToken = Text.End(BaseName, 7),
    YearAttempt = try Number.FromText(Text.Start(MonthToken, 4)),
    MonthAttempt = try Number.FromText(Text.End(MonthToken, 2)),
    IsValid =
        not YearAttempt[HasError]
        and not MonthAttempt[HasError]
        and MonthAttempt[Value] >= 1
        and MonthAttempt[Value] <= 12,
    Result =
        if IsValid then
            #date(
                Number.RoundDown(YearAttempt[Value]),
                Number.RoundDown(MonthAttempt[Value]),
                1
            )
        else
            null
in
    Result

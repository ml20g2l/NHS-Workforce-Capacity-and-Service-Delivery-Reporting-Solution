(fileName as text) as nullable date =>
let
    BaseName = Text.BeforeDelimiter(fileName, ".", {0, RelativePosition.FromEnd}),
    CandidateTokens =
        if Text.Length(BaseName) < 7 then
            {}
        else
            List.Transform(
                {0 .. Text.Length(BaseName) - 7},
                each Text.Range(BaseName, _, 7)
            ),
    ValidTokens = List.Select(
        CandidateTokens,
        (token as text) =>
            let
                YearAttempt = try Number.FromText(Text.Start(token, 4)),
                MonthAttempt = try Number.FromText(Text.End(token, 2))
            in
                Text.Middle(token, 4, 1) = "-"
                    and not YearAttempt[HasError]
                    and not MonthAttempt[HasError]
                    and MonthAttempt[Value] >= 1
                    and MonthAttempt[Value] <= 12
    ),
    MonthToken =
        if List.Count(ValidTokens) = 0 then
            null
        else
            List.Last(ValidTokens),
    YearAttempt =
        if MonthToken = null then
            try error "No YYYY-MM token"
        else
            try Number.FromText(Text.Start(MonthToken, 4)),
    MonthAttempt =
        if MonthToken = null then
            try error "No YYYY-MM token"
        else
            try Number.FromText(Text.End(MonthToken, 2)),
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

(value as any) as nullable date =>
let
    Result =
        if value = null then
            null
        else if Value.Is(value, type date)
            or Value.Is(value, type datetime)
            or Value.Is(value, type datetimezone) then
            Date.From(value)
        else
            let
                AsText = Text.Trim(Text.From(value)),
                BritishAttempt = try Date.FromText(AsText, [Culture = "en-GB"]),
                ISOAttempt = try Date.FromText(AsText, [Culture = "en-US"])
            in
                if not BritishAttempt[HasError] then
                    BritishAttempt[Value]
                else if not ISOAttempt[HasError] then
                    ISOAttempt[Value]
                else
                    null
in
    Result

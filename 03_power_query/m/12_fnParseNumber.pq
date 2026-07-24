(value as any) as nullable number =>
let
    Result =
        if value = null then
            null
        else if Value.Is(value, type number) then
            Number.From(value)
        else
            let
                AsText = Text.Trim(Text.From(value)),
                BritishAttempt = try Number.FromText(AsText, "en-GB"),
                USAttempt = try Number.FromText(AsText, "en-US")
            in
                if AsText = "" then
                    null
                else if not BritishAttempt[HasError] then
                    BritishAttempt[Value]
                else if not USAttempt[HasError] then
                    USAttempt[Value]
                else
                    null
in
    Result

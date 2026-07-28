let
    StartMonth = Date.StartOfMonth(pReportingStartMonth),
    EndMonth = Date.StartOfMonth(pReportingEndMonth),
    MonthCount =
        (Date.Year(EndMonth) - Date.Year(StartMonth)) * 12
            + Date.Month(EndMonth)
            - Date.Month(StartMonth)
            + 1,
    MonthList = List.Transform(
        {0 .. MonthCount - 1},
        each Date.AddMonths(StartMonth, _)
    ),
    Source = Table.FromList(
        MonthList,
        Splitter.SplitByNothing(),
        {"ReportingMonth"}
    ),
    Typed = Table.TransformColumnTypes(
        Source,
        {{"ReportingMonth", type date}}
    ),
    AddMonthKey = Table.AddColumn(
        Typed,
        "MonthKey",
        each Date.Year([ReportingMonth]) * 100 + Date.Month([ReportingMonth]),
        Int64.Type
    ),
    AddMonthLabel = Table.AddColumn(
        AddMonthKey,
        "MonthLabel",
        each Date.ToText([ReportingMonth], "MMM yyyy", "en-GB"),
        type text
    ),
    AddCalendarYear = Table.AddColumn(
        AddMonthLabel,
        "CalendarYear",
        each Date.Year([ReportingMonth]),
        Int64.Type
    ),
    AddCalendarMonthNumber = Table.AddColumn(
        AddCalendarYear,
        "CalendarMonthNumber",
        each Date.Month([ReportingMonth]),
        Int64.Type
    ),
    AddFinancialYearStart = Table.AddColumn(
        AddCalendarMonthNumber,
        "FinancialYearStart",
        each
            if Date.Month([ReportingMonth]) >= 4 then
                Date.Year([ReportingMonth])
            else
                Date.Year([ReportingMonth]) - 1,
        Int64.Type
    ),
    AddFinancialYear = Table.AddColumn(
        AddFinancialYearStart,
        "FinancialYear",
        each
            "FY"
                & Text.From([FinancialYearStart])
                & "/"
                & Text.End(Text.From([FinancialYearStart] + 1), 2),
        type text
    ),
    AddFinancialMonthNumber = Table.AddColumn(
        AddFinancialYear,
        "FinancialMonthNumber",
        each Number.Mod(Date.Month([ReportingMonth]) - 4 + 12, 12) + 1,
        Int64.Type
    ),
    AddFinancialQuarter = Table.AddColumn(
        AddFinancialMonthNumber,
        "FinancialQuarter",
        each "Q" & Text.From(Number.RoundUp([FinancialMonthNumber] / 3)),
        type text
    ),
    Reordered = Table.ReorderColumns(
        AddFinancialQuarter,
        {
            "MonthKey",
            "ReportingMonth",
            "MonthLabel",
            "CalendarYear",
            "CalendarMonthNumber",
            "FinancialYear",
            "FinancialQuarter",
            "FinancialMonthNumber",
            "FinancialYearStart"
        }
    )
in
    Reordered

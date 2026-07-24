let
    WorkforceMetrics = #table(
        {"SourceDataset", "Metric", "RawValue", "AcceptedValue"},
        {
            {
                "NHS Workforce Statistics",
                "Rows",
                Table.RowCount(dqWorkforceClassified),
                Table.RowCount(
                    Table.SelectRows(
                        dqWorkforceClassified,
                        each [RecordStatus] = "Accepted"
                    )
                )
            },
            {
                "NHS Workforce Statistics",
                "FTE",
                List.Sum(
                    Table.SelectRows(
                        dqWorkforceClassified,
                        each [DataType] = "FTE"
                    )[MeasureValue]
                ),
                List.Sum(
                    Table.SelectRows(
                        dqWorkforceClassified,
                        each [DataType] = "FTE"
                            and [RecordStatus] = "Accepted"
                    )[MeasureValue]
                )
            },
            {
                "NHS Workforce Statistics",
                "Headcount",
                List.Sum(
                    Table.SelectRows(
                        dqWorkforceClassified,
                        each [DataType] = "HC"
                    )[MeasureValue]
                ),
                List.Sum(
                    Table.SelectRows(
                        dqWorkforceClassified,
                        each [DataType] = "HC"
                            and [RecordStatus] = "Accepted"
                    )[MeasureValue]
                )
            }
        }
    ),
    AbsenceMetrics = #table(
        {"SourceDataset", "Metric", "RawValue", "AcceptedValue"},
        {
            {
                "NHS Sickness Absence Rates",
                "Rows",
                Table.RowCount(dqAbsenceClassified),
                Table.RowCount(
                    Table.SelectRows(
                        dqAbsenceClassified,
                        each [RecordStatus] = "Accepted"
                    )
                )
            },
            {
                "NHS Sickness Absence Rates",
                "FTE days lost",
                List.Sum(dqAbsenceClassified[FTEDaysLost]),
                List.Sum(
                    Table.SelectRows(
                        dqAbsenceClassified,
                        each [RecordStatus] = "Accepted"
                    )[FTEDaysLost]
                )
            },
            {
                "NHS Sickness Absence Rates",
                "FTE days available",
                List.Sum(dqAbsenceClassified[FTEDaysAvailable]),
                List.Sum(
                    Table.SelectRows(
                        dqAbsenceClassified,
                        each [RecordStatus] = "Accepted"
                    )[FTEDaysAvailable]
                )
            }
        }
    ),
    ActivityWithTotals = Table.AddColumn(
        Table.AddColumn(
            Table.AddColumn(
                dqServiceActivityClassified,
                "_TotalAttendances",
                each [AttendancesType1] + [AttendancesType2] + [AttendancesOther],
                type nullable number
            ),
            "_TotalOver4Hours",
            each [Over4HoursType1] + [Over4HoursType2] + [Over4HoursOther],
            type nullable number
        ),
        "_TotalEmergencyAdmissions",
        each [EmergencyAdmissionsViaAEType1]
            + [EmergencyAdmissionsViaAEType2]
            + [EmergencyAdmissionsViaAEOther]
            + [OtherEmergencyAdmissions],
        type nullable number
    ),
    AcceptedActivity = Table.SelectRows(
        ActivityWithTotals,
        each [RecordStatus] = "Accepted"
    ),
    ActivityMetrics = #table(
        {"SourceDataset", "Metric", "RawValue", "AcceptedValue"},
        {
            {
                "A&E Attendances and Emergency Admissions",
                "Rows",
                Table.RowCount(ActivityWithTotals),
                Table.RowCount(AcceptedActivity)
            },
            {
                "A&E Attendances and Emergency Admissions",
                "Total attendances",
                List.Sum(ActivityWithTotals[_TotalAttendances]),
                List.Sum(AcceptedActivity[_TotalAttendances])
            },
            {
                "A&E Attendances and Emergency Admissions",
                "Attendances over four hours",
                List.Sum(ActivityWithTotals[_TotalOver4Hours]),
                List.Sum(AcceptedActivity[_TotalOver4Hours])
            },
            {
                "A&E Attendances and Emergency Admissions",
                "Emergency admissions",
                List.Sum(ActivityWithTotals[_TotalEmergencyAdmissions]),
                List.Sum(AcceptedActivity[_TotalEmergencyAdmissions])
            }
        }
    ),
    Combined = Table.Combine({WorkforceMetrics, AbsenceMetrics, ActivityMetrics}),
    AddDifference = Table.AddColumn(
        Combined,
        "Difference",
        each [RawValue] - [AcceptedValue],
        type number
    ),
    AddDifferenceReason = Table.AddColumn(
        AddDifference,
        "DifferenceReason",
        each
            if [Difference] = 0 then
                "No difference"
            else
                "Rejected and Review Required records are excluded from accepted totals; inspect qryPowerQueryExceptions",
        type text
    )
in
    AddDifferenceReason

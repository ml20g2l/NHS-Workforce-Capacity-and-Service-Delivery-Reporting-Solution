let
    WorkforceMetrics = #table(
        {"SourceDataset", "Metric", "RawValue", "AcceptedValue", "ReportableValue"},
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
                ),
                Table.RowCount(
                    Table.SelectRows(
                        dqWorkforceClassified,
                        each [RecordStatus] = "Accepted"
                            and [InclusionFlag] = true
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
                ),
                List.Sum(
                    Table.SelectRows(
                        dqWorkforceClassified,
                        each [DataType] = "FTE"
                            and [RecordStatus] = "Accepted"
                            and [InclusionFlag] = true
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
                ),
                List.Sum(
                    Table.SelectRows(
                        dqWorkforceClassified,
                        each [DataType] = "HC"
                            and [RecordStatus] = "Accepted"
                            and [InclusionFlag] = true
                    )[MeasureValue]
                )
            }
        }
    ),
    AbsenceMetrics = #table(
        {"SourceDataset", "Metric", "RawValue", "AcceptedValue", "ReportableValue"},
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
                ),
                Table.RowCount(
                    Table.SelectRows(
                        dqAbsenceClassified,
                        each [RecordStatus] = "Accepted"
                            and [InclusionFlag] = true
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
                ),
                List.Sum(
                    Table.SelectRows(
                        dqAbsenceClassified,
                        each [RecordStatus] = "Accepted"
                            and [InclusionFlag] = true
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
                ),
                List.Sum(
                    Table.SelectRows(
                        dqAbsenceClassified,
                        each [RecordStatus] = "Accepted"
                            and [InclusionFlag] = true
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
    ReportableActivity = Table.SelectRows(
        AcceptedActivity,
        each [InclusionFlag] = true
    ),
    ActivityMetrics = #table(
        {"SourceDataset", "Metric", "RawValue", "AcceptedValue", "ReportableValue"},
        {
            {
                "A&E Attendances and Emergency Admissions",
                "Rows",
                Table.RowCount(ActivityWithTotals),
                Table.RowCount(AcceptedActivity),
                Table.RowCount(ReportableActivity)
            },
            {
                "A&E Attendances and Emergency Admissions",
                "Total attendances",
                List.Sum(ActivityWithTotals[_TotalAttendances]),
                List.Sum(AcceptedActivity[_TotalAttendances]),
                List.Sum(ReportableActivity[_TotalAttendances])
            },
            {
                "A&E Attendances and Emergency Admissions",
                "Attendances over four hours",
                List.Sum(ActivityWithTotals[_TotalOver4Hours]),
                List.Sum(AcceptedActivity[_TotalOver4Hours]),
                List.Sum(ReportableActivity[_TotalOver4Hours])
            },
            {
                "A&E Attendances and Emergency Admissions",
                "Emergency admissions",
                List.Sum(ActivityWithTotals[_TotalEmergencyAdmissions]),
                List.Sum(AcceptedActivity[_TotalEmergencyAdmissions]),
                List.Sum(ReportableActivity[_TotalEmergencyAdmissions])
            }
        }
    ),
    Combined = Table.Combine({WorkforceMetrics, AbsenceMetrics, ActivityMetrics}),
    AddDifference = Table.AddColumn(
        Combined,
        "RawToAcceptedDifference",
        each [RawValue] - [AcceptedValue],
        type number
    ),
    AddScopeDifference = Table.AddColumn(
        AddDifference,
        "AcceptedToReportableDifference",
        each [AcceptedValue] - [ReportableValue],
        type number
    ),
    AddDifferenceReason = Table.AddColumn(
        AddScopeDifference,
        "DifferenceReason",
        each
            if [RawToAcceptedDifference] = 0
                and [AcceptedToReportableDifference] = 0 then
                "No quality or scope difference"
            else if [RawToAcceptedDifference] = 0 then
                "Accepted rows outside the approved London reporting cohort are excluded from reportable totals"
            else if [AcceptedToReportableDifference] = 0 then
                "Rejected and Review Required records are excluded from accepted totals"
            else
                "Quality exclusions and reporting-scope exclusions both apply; inspect exceptions and the organisation reference",
        type text
    )
in
    AddDifferenceReason

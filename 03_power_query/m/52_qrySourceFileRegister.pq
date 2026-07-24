let
    WorkforceFiles = fnGetSourceFiles(
        pWorkforceFolder,
        "NHS Workforce Statistics"
    ),
    AbsenceFiles = fnGetSourceFiles(
        pAbsenceFolder,
        "NHS Sickness Absence Rates"
    ),
    ActivityFiles = fnGetSourceFiles(
        pActivityFolder,
        "A&E Attendances and Emergency Admissions"
    ),
    Combined = Table.Combine({WorkforceFiles, AbsenceFiles, ActivityFiles}),
    RemoveBinary = Table.RemoveColumns(Combined, {"Content"}),
    Sorted = Table.Sort(
        RemoveBinary,
        {
            {"SourceDataset", Order.Ascending},
            {"FileReportingMonth", Order.Ascending},
            {"FileVersionRank", Order.Ascending}
        }
    )
in
    Sorted

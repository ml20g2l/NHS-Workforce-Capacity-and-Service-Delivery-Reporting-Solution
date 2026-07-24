$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$cycleRoot = Join-Path $projectRoot "04_processed_data\reporting_cycles"
$logRoot = Join-Path $projectRoot "05_reporting_controls\refresh_logs"
$rawJuly = Join-Path $PSScriptRoot "raw\service_activity\ae_activity_2024-07.csv"

New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

$cycleDefinitions = @(
    [pscustomobject]@{
        Cycle = "Cycle1"
        Folder = "cycle_1_q1"
        MonthCount = 3
        AbsenceFiles = 3
        ActivityFiles = 3
        EndMonth = "2024-06-01"
    }
    [pscustomobject]@{
        Cycle = "Cycle2"
        Folder = "cycle_2_july_added"
        MonthCount = 4
        AbsenceFiles = 4
        ActivityFiles = 4
        EndMonth = "2024-07-01"
    }
    [pscustomobject]@{
        Cycle = "Cycle3"
        Folder = "cycle_3_version_control"
        MonthCount = 4
        AbsenceFiles = 4
        ActivityFiles = 6
        EndMonth = "2024-07-01"
    }
)

$results = [System.Collections.Generic.List[object]]::new()

function Add-Check {
    param(
        [string]$Cycle,
        [string]$CheckID,
        [string]$Check,
        [bool]$Passed,
        [string]$Evidence,
        [string]$Severity
    )

    $results.Add([pscustomobject]@{
        ValidationTimestampUTC = [datetime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
        Cycle = $Cycle
        CheckID = $CheckID
        Check = $Check
        Result = if ($Passed) { "PASS" } else { "FAIL" }
        Evidence = $Evidence
        SeverityIfFailed = $Severity
    })
}

foreach ($definition in $cycleDefinitions) {
    $folder = Join-Path $cycleRoot $definition.Folder
    $manifestPath = Join-Path $folder "cycle_manifest.csv"
    $parametersPath = Join-Path $folder "cycle_parameters.csv"
    $absenceFolder = Join-Path $folder "absence"
    $activityFolder = Join-Path $folder "service_activity"

    $folderExists = Test-Path -LiteralPath $folder
    Add-Check $definition.Cycle "P7-001" "Cycle folder exists" $folderExists $folder "Critical"
    if (-not $folderExists) {
        continue
    }

    $manifestExists = Test-Path -LiteralPath $manifestPath
    Add-Check $definition.Cycle "P7-002" "Cycle manifest exists" $manifestExists $manifestPath "Critical"
    if (-not $manifestExists) {
        continue
    }

    $manifest = Import-Csv -LiteralPath $manifestPath
    $distinctMonths = @($manifest.ReportingMonth | Sort-Object -Unique)
    Add-Check `
        $definition.Cycle `
        "P7-003" `
        "Manifest month coverage" `
        ($distinctMonths.Count -eq $definition.MonthCount) `
        "Expected=$($definition.MonthCount); Actual=$($distinctMonths.Count); Months=$($distinctMonths -join ',')" `
        "Critical"

    $absenceCount = (Get-ChildItem -LiteralPath $absenceFolder -File -Filter "*.csv").Count
    $activityCount = (Get-ChildItem -LiteralPath $activityFolder -File -Filter "*.csv").Count
    Add-Check `
        $definition.Cycle `
        "P7-004" `
        "Absence file count" `
        ($absenceCount -eq $definition.AbsenceFiles) `
        "Expected=$($definition.AbsenceFiles); Actual=$absenceCount" `
        "High"
    Add-Check `
        $definition.Cycle `
        "P7-005" `
        "A&E file count" `
        ($activityCount -eq $definition.ActivityFiles) `
        "Expected=$($definition.ActivityFiles); Actual=$activityCount" `
        "High"

    $hashFailures = [System.Collections.Generic.List[string]]::new()
    foreach ($row in $manifest) {
        $datasetFolder = if ($row.Dataset -eq "Sickness Absence") {
            $absenceFolder
        } else {
            $activityFolder
        }
        $filePath = Join-Path $datasetFolder $row.SourceFile
        if (-not (Test-Path -LiteralPath $filePath)) {
            $hashFailures.Add("Missing:$($row.SourceFile)")
            continue
        }
        $actualHash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
        if ($actualHash -ne $row.SHA256) {
            $hashFailures.Add("Hash mismatch:$($row.SourceFile)")
        }
    }
    Add-Check `
        $definition.Cycle `
        "P7-006" `
        "Manifest hashes match generated files" `
        ($hashFailures.Count -eq 0) `
        $(if ($hashFailures.Count -eq 0) { "All $($manifest.Count) rows matched" } else { $hashFailures -join ";" }) `
        "Critical"

    $parametersExist = Test-Path -LiteralPath $parametersPath
    Add-Check $definition.Cycle "P7-007" "Cycle parameter file exists" $parametersExist $parametersPath "High"
    if ($parametersExist) {
        $parameters = Import-Csv -LiteralPath $parametersPath
        $endMonthRow = $parameters | Where-Object ParameterName -eq "ReportingEndMonth"
        Add-Check `
            $definition.Cycle `
            "P7-008" `
            "Reporting end month matches cycle" `
            ($endMonthRow.ParameterValue -eq $definition.EndMonth) `
            "Expected=$($definition.EndMonth); Actual=$($endMonthRow.ParameterValue)" `
            "Critical"
    }
}

$cycle3Folder = Join-Path $cycleRoot "cycle_3_version_control"
$cycle3Original = Join-Path $cycle3Folder "service_activity\ae_activity_2024-07.csv"
$cycle3Duplicate = Join-Path $cycle3Folder "service_activity\ae_activity_2024-07_duplicate.csv"
$cycle3Revised = Join-Path $cycle3Folder "service_activity\ae_activity_2024-07_revised.csv"
$revisionLog = Join-Path $cycle3Folder "controlled_revision_log.csv"

$rawHash = (Get-FileHash -LiteralPath $rawJuly -Algorithm SHA256).Hash
$cycleOriginalHash = (Get-FileHash -LiteralPath $cycle3Original -Algorithm SHA256).Hash
$duplicateHash = (Get-FileHash -LiteralPath $cycle3Duplicate -Algorithm SHA256).Hash
$revisedHash = (Get-FileHash -LiteralPath $cycle3Revised -Algorithm SHA256).Hash

Add-Check `
    "Cycle3" `
    "P7-009" `
    "Preserved raw July A&E file matches Cycle 3 original" `
    ($rawHash -eq $cycleOriginalHash) `
    "RawHash=$rawHash; CycleOriginalHash=$cycleOriginalHash" `
    "Critical"
Add-Check `
    "Cycle3" `
    "P7-010" `
    "Controlled duplicate is byte-identical" `
    ($cycleOriginalHash -eq $duplicateHash) `
    "OriginalHash=$cycleOriginalHash; DuplicateHash=$duplicateHash" `
    "Critical"
Add-Check `
    "Cycle3" `
    "P7-011" `
    "Controlled revision differs from original" `
    ($cycleOriginalHash -ne $revisedHash) `
    "OriginalHash=$cycleOriginalHash; RevisedHash=$revisedHash" `
    "Critical"

$originalModified = (Get-Item -LiteralPath $cycle3Original).LastWriteTime
$duplicateModified = (Get-Item -LiteralPath $cycle3Duplicate).LastWriteTime
$revisedModified = (Get-Item -LiteralPath $cycle3Revised).LastWriteTime
$orderingPassed = $originalModified -lt $duplicateModified -and $duplicateModified -lt $revisedModified
Add-Check `
    "Cycle3" `
    "P7-012" `
    "Modified timestamps select revised file as latest" `
    $orderingPassed `
    "Original=$originalModified; Duplicate=$duplicateModified; Revised=$revisedModified" `
    "Critical"

$revisionRows = @(Import-Csv -LiteralPath $revisionLog)
$revisionPassed = (
    $revisionRows.Count -eq 1 -and
    [int64]$revisionRows[0].RevisedValue - [int64]$revisionRows[0].OriginalValue -eq 1 -and
    $revisionRows[0].OrganisationCode -eq "RAN"
)
Add-Check `
    "Cycle3" `
    "P7-013" `
    "Controlled revision log records exactly one-unit RAN change" `
    $revisionPassed `
    "Rows=$($revisionRows.Count); Organisation=$($revisionRows[0].OrganisationCode); Change=$($revisionRows[0].OriginalValue)->$($revisionRows[0].RevisedValue)" `
    "Critical"

$validationLogPath = Join-Path $logRoot "phase7_pre_refresh_validation.csv"
$results |
    Sort-Object Cycle, CheckID |
    Export-Csv -LiteralPath $validationLogPath -NoTypeInformation -Encoding UTF8

$summaryPath = Join-Path $logRoot "phase7_cycle_expected_inputs.csv"
$cycleDefinitions |
    Select-Object `
        Cycle,
        Folder,
        MonthCount,
        AbsenceFiles,
        ActivityFiles,
        EndMonth |
    Export-Csv -LiteralPath $summaryPath -NoTypeInformation -Encoding UTF8

$failed = @($results | Where-Object Result -eq "FAIL")
[pscustomobject]@{
    Checks = $results.Count
    Passed = @($results | Where-Object Result -eq "PASS").Count
    Failed = $failed.Count
    ValidationLog = $validationLogPath
    ExpectedInputs = $summaryPath
} | Format-List

if ($failed.Count -gt 0) {
    $failed | Format-Table Cycle, CheckID, Check, Evidence -AutoSize
    exit 1
}

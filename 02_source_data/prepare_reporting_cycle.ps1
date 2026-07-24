param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Cycle1", "Cycle2", "Cycle3")]
    [string]$Cycle
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$absenceSource = Join-Path $PSScriptRoot "raw\absence"
$activitySource = Join-Path $PSScriptRoot "raw\service_activity"
$cycleRoot = Join-Path $projectRoot "04_processed_data\reporting_cycles"

$cycleConfig = @{
    Cycle1 = @{
        Folder = "cycle_1_q1"
        EndMonth = "2024-06-01"
        Months = @("2024-04", "2024-05", "2024-06")
        Purpose = "Initial Q1 refresh using April to June 2024."
    }
    Cycle2 = @{
        Folder = "cycle_2_july_added"
        EndMonth = "2024-07-01"
        Months = @("2024-04", "2024-05", "2024-06", "2024-07")
        Purpose = "Incremental refresh after adding July 2024."
    }
    Cycle3 = @{
        Folder = "cycle_3_version_control"
        EndMonth = "2024-07-01"
        Months = @("2024-04", "2024-05", "2024-06", "2024-07")
        Purpose = "Controlled duplicate and revised-file test for July 2024."
    }
}

$config = $cycleConfig[$Cycle]
$destination = Join-Path $cycleRoot $config.Folder
$absenceDestination = Join-Path $destination "absence"
$activityDestination = Join-Path $destination "service_activity"

New-Item -ItemType Directory -Force -Path $absenceDestination | Out-Null
New-Item -ItemType Directory -Force -Path $activityDestination | Out-Null

$manifestRows = [System.Collections.Generic.List[object]]::new()

foreach ($month in $config.Months) {
    $absenceName = "nhs_sickness_absence_${month}.csv"
    $activityName = "ae_activity_${month}.csv"
    $absenceFile = Join-Path $absenceSource $absenceName
    $activityFile = Join-Path $activitySource $activityName

    if (-not (Test-Path -LiteralPath $absenceFile)) {
        throw "Missing source file: $absenceFile"
    }
    if (-not (Test-Path -LiteralPath $activityFile)) {
        throw "Missing source file: $activityFile"
    }

    $absenceCopy = Join-Path $absenceDestination $absenceName
    $activityCopy = Join-Path $activityDestination $activityName
    Copy-Item -LiteralPath $absenceFile -Destination $absenceCopy -Force
    Copy-Item -LiteralPath $activityFile -Destination $activityCopy -Force

    $manifestRows.Add([pscustomobject]@{
        Cycle = $Cycle
        Dataset = "Sickness Absence"
        ReportingMonth = $month
        SourceFile = $absenceName
        TestClassification = "Official source"
        ExpectedFileDisposition = "Active"
        SHA256 = (Get-FileHash -LiteralPath $absenceCopy -Algorithm SHA256).Hash
    })
    $manifestRows.Add([pscustomobject]@{
        Cycle = $Cycle
        Dataset = "A&E Activity"
        ReportingMonth = $month
        SourceFile = $activityName
        TestClassification = "Official source"
        ExpectedFileDisposition = if ($Cycle -eq "Cycle3" -and $month -eq "2024-07") {
            "Duplicate - superseded"
        } else {
            "Active"
        }
        SHA256 = (Get-FileHash -LiteralPath $activityCopy -Algorithm SHA256).Hash
    })
}

$qaChange = $null
if ($Cycle -eq "Cycle3") {
    $julyOriginal = Join-Path $activityDestination "ae_activity_2024-07.csv"
    $duplicateName = "ae_activity_2024-07_duplicate.csv"
    $revisedName = "ae_activity_2024-07_revised.csv"
    $duplicateFile = Join-Path $activityDestination $duplicateName
    $revisedFile = Join-Path $activityDestination $revisedName

    Copy-Item -LiteralPath $julyOriginal -Destination $duplicateFile -Force
    Copy-Item -LiteralPath $julyOriginal -Destination $revisedFile -Force

    $revisedRows = Import-Csv -LiteralPath $revisedFile
    $targetRow = $revisedRows |
        Where-Object {
            $_.'Org Code' -ne "TOTAL" -and
            $_.'Parent Org' -like "*LONDON*"
        } |
        Select-Object -First 1

    if ($null -eq $targetRow) {
        throw "No London provider row was available for the controlled revision."
    }

    $measureName = "A&E attendances Type 1"
    $originalValue = [int64]$targetRow.$measureName
    $revisedValue = $originalValue + 1
    $targetRow.$measureName = [string]$revisedValue
    $revisedRows | Export-Csv -LiteralPath $revisedFile -NoTypeInformation -Encoding UTF8

    (Get-Item -LiteralPath $julyOriginal).LastWriteTime = [datetime]"2026-01-01T00:00:00"
    (Get-Item -LiteralPath $duplicateFile).LastWriteTime = [datetime]"2026-01-01T00:01:00"
    (Get-Item -LiteralPath $revisedFile).LastWriteTime = [datetime]"2026-01-01T00:02:00"

    $manifestRows.Add([pscustomobject]@{
        Cycle = $Cycle
        Dataset = "A&E Activity"
        ReportingMonth = "2024-07"
        SourceFile = $duplicateName
        TestClassification = "Controlled exact duplicate"
        ExpectedFileDisposition = "Duplicate - superseded"
        SHA256 = (Get-FileHash -LiteralPath $duplicateFile -Algorithm SHA256).Hash
    })
    $manifestRows.Add([pscustomobject]@{
        Cycle = $Cycle
        Dataset = "A&E Activity"
        ReportingMonth = "2024-07"
        SourceFile = $revisedName
        TestClassification = "Controlled revised version"
        ExpectedFileDisposition = "Active"
        SHA256 = (Get-FileHash -LiteralPath $revisedFile -Algorithm SHA256).Hash
    })

    $qaChange = [pscustomobject]@{
        SourceFile = $revisedName
        OrganisationCode = $targetRow.'Org Code'
        OrganisationName = $targetRow.'Org name'
        Field = $measureName
        OriginalValue = $originalValue
        RevisedValue = $revisedValue
        ChangeReason = "Controlled pipeline test; not an observed NHS source correction"
    }
}

$manifestPath = Join-Path $destination "cycle_manifest.csv"
$manifestRows |
    Sort-Object Dataset, ReportingMonth, SourceFile |
    Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8

$parameterRows = @(
    [pscustomobject]@{ ParameterName = "WorkforceFolder"; ParameterValue = (Join-Path $projectRoot "04_processed_data\staging\workforce") }
    [pscustomobject]@{ ParameterName = "AbsenceFolder"; ParameterValue = $absenceDestination }
    [pscustomobject]@{ ParameterName = "ActivityFolder"; ParameterValue = $activityDestination }
    [pscustomobject]@{ ParameterName = "ReferenceFolder"; ParameterValue = (Join-Path $projectRoot "02_source_data\reference") }
    [pscustomobject]@{ ParameterName = "ReportingStartMonth"; ParameterValue = "2024-04-01" }
    [pscustomobject]@{ ParameterName = "ReportingEndMonth"; ParameterValue = $config.EndMonth }
)
$parameterRows |
    Export-Csv -LiteralPath (Join-Path $destination "cycle_parameters.csv") -NoTypeInformation -Encoding UTF8

if ($null -ne $qaChange) {
    $qaChange |
        Export-Csv -LiteralPath (Join-Path $destination "controlled_revision_log.csv") -NoTypeInformation -Encoding UTF8
}

[pscustomobject]@{
    Cycle = $Cycle
    Purpose = $config.Purpose
    OutputFolder = $destination
    AbsenceFiles = (Get-ChildItem -LiteralPath $absenceDestination -File -Filter "*.csv").Count
    ActivityFiles = (Get-ChildItem -LiteralPath $activityDestination -File -Filter "*.csv").Count
    ReportingEndMonth = $config.EndMonth
    Manifest = $manifestPath
} | Format-List

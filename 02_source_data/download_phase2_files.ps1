$ErrorActionPreference = "Stop"

$sourceDataRoot = $PSScriptRoot
$rawRoot = Join-Path $sourceDataRoot "raw"
$absenceRoot = Join-Path $rawRoot "absence"
$activityRoot = Join-Path $rawRoot "service_activity"
$referenceRoot = Join-Path $sourceDataRoot "reference"

New-Item -ItemType Directory -Force -Path $absenceRoot, $activityRoot, $referenceRoot | Out-Null

$downloads = @(
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2024-04"
        Url = "https://files.digital.nhs.uk/77/0A5C5E/NHS%20Sickness%20Absence%20rates%20CSV%2C%20April%202024.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2024-04.csv"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2024-05"
        Url = "https://files.digital.nhs.uk/EA/F7E55C/NHS%20Sickness%20Absence%20rates%20CSV%2C%20May%202024.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2024-05.csv"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2024-06"
        Url = "https://files.digital.nhs.uk/06/003F05/NHS%20Sickness%20Absence%20rates%20CSV%2C%20June%202024.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2024-06.csv"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2024-07"
        Url = "https://files.digital.nhs.uk/B1/7F4352/NHS%20Sickness%20Absence%20rates%20CSV%2C%20July%202024.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2024-07.csv"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2024-08"
        Url = "https://files.digital.nhs.uk/D6/70EC91/NHS%20Sickness%20Absence%20rates%20CSV%2C%20August%202024.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2024-08.csv"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2024-09"
        Url = "https://files.digital.nhs.uk/51/79BEE8/NHS%20Sickness%20Absence%20rates%20CSV%2C%20September%202024.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2024-09.csv"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2024-10"
        Url = "https://files.digital.nhs.uk/30/F94775/NHS%20Sickness%20Absence%20rates%20CSV%2C%20October%202024.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2024-10.csv"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2024-11"
        Url = "https://files.digital.nhs.uk/FC/EFAF8A/NHS%20Sickness%20Absence%20rates%20CSV%2C%20November%202024.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2024-11.csv"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2024-12"
        Url = "https://files.digital.nhs.uk/CC/4222CE/NHS%20Sickness%20Absence%20rates%20CSV%2C%20December%202024.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2024-12.csv"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2025-01"
        Url = "https://files.digital.nhs.uk/1D/A53C43/NHS%20Sickness%20Absence%20rates%20CSV%2C%20January%202025.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2025-01.csv"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        Month = "2025-02"
        Url = "https://files.digital.nhs.uk/29/DECFCE/NHS%20Sickness%20Absence%20rates%20CSV%2C%20February%202025.csv"
        Destination = Join-Path $absenceRoot "nhs_sickness_absence_2025-02.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2024-04"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2024/11/Monthly-AE-April-2024-revised.csv"
        Destination = Join-Path $activityRoot "ae_activity_2024-04.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2024-05"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2024/06/Monthly-AE-May-2024.csv"
        Destination = Join-Path $activityRoot "ae_activity_2024-05.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2024-06"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2024/07/Monthly-AE-June-2024.csv"
        Destination = Join-Path $activityRoot "ae_activity_2024-06.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2024-07"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2024/11/Monthly-AE-July-2024-revised.csv"
        Destination = Join-Path $activityRoot "ae_activity_2024-07.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2024-08"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2024/09/Monthly-AE-August-2024.csv"
        Destination = Join-Path $activityRoot "ae_activity_2024-08.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2024-09"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2024/10/Monthly-AE-September-2024.csv"
        Destination = Join-Path $activityRoot "ae_activity_2024-09.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2024-10"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2025/05/Monthly-AE-October-2024-revised.csv"
        Destination = Join-Path $activityRoot "ae_activity_2024-10.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2024-11"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2025/05/Monthly-AE-November-2024-revised.csv"
        Destination = Join-Path $activityRoot "ae_activity_2024-11.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2024-12"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2025/01/Monthly-AE-December-2024.csv"
        Destination = Join-Path $activityRoot "ae_activity_2024-12.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2025-01"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2025/02/Monthly-AE-January-2025.csv"
        Destination = Join-Path $activityRoot "ae_activity_2025-01.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        Month = "2025-02"
        Url = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2025/05/Monthly-AE-February-2025-revised.csv"
        Destination = Join-Path $activityRoot "ae_activity_2025-02.csv"
    }
)

foreach ($download in $downloads) {
    if ((Test-Path -LiteralPath $download.Destination) -and
        ((Get-Item -LiteralPath $download.Destination).Length -gt 0)) {
        Write-Host "SKIP  $($download.Dataset) $($download.Month)"
        continue
    }

    Write-Host "GET   $($download.Dataset) $($download.Month)"
    Invoke-WebRequest -Uri $download.Url -OutFile $download.Destination
}

$manifestRows = foreach ($download in $downloads) {
    $file = Get-Item -LiteralPath $download.Destination
    $hash = Get-FileHash -LiteralPath $download.Destination -Algorithm SHA256
    [PSCustomObject]@{
        Dataset = $download.Dataset
        ReportingMonth = $download.Month
        FileName = $file.Name
        FileSizeBytes = $file.Length
        SHA256 = $hash.Hash
        SourceUrl = $download.Url
        DownloadedAt = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
}

# Add the three representative files downloaded before this script.
$existingFiles = @(
    [PSCustomObject]@{
        Dataset = "Workforce"
        ReportingMonth = "through 2025-03"
        Path = Join-Path $rawRoot "workforce\nhs_workforce_statistics_2025-03_csv.zip"
        SourceUrl = "https://files.digital.nhs.uk/D1/6E6F97/NHS%20Workforce%20Statistics%2C%20March%202025%20csv%20files.zip"
    },
    [PSCustomObject]@{
        Dataset = "Sickness Absence"
        ReportingMonth = "2025-03"
        Path = Join-Path $absenceRoot "nhs_sickness_absence_2025-03.csv"
        SourceUrl = "https://files.digital.nhs.uk/77/67AF66/NHS%20Sickness%20Absence%20rates%20CSV%2C%20March%202025.csv"
    },
    [PSCustomObject]@{
        Dataset = "A&E Activity"
        ReportingMonth = "2025-03"
        Path = Join-Path $activityRoot "ae_activity_2025-03.csv"
        SourceUrl = "https://www.england.nhs.uk/statistics/wp-content/uploads/sites/2/2025/04/Monthly-AE-March-2025.csv"
    }
)

foreach ($existing in $existingFiles) {
    $file = Get-Item -LiteralPath $existing.Path
    $hash = Get-FileHash -LiteralPath $existing.Path -Algorithm SHA256
    $manifestRows += [PSCustomObject]@{
        Dataset = $existing.Dataset
        ReportingMonth = $existing.ReportingMonth
        FileName = $file.Name
        FileSizeBytes = $file.Length
        SHA256 = $hash.Hash
        SourceUrl = $existing.SourceUrl
        DownloadedAt = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
}

$manifestPath = Join-Path $referenceRoot "phase2_download_manifest.csv"
$manifestRows |
    Sort-Object Dataset, ReportingMonth |
    Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding utf8

$absenceCount = (Get-ChildItem -LiteralPath $absenceRoot -Filter "nhs_sickness_absence_*.csv").Count
$activityCount = (Get-ChildItem -LiteralPath $activityRoot -Filter "ae_activity_*.csv").Count

Write-Host ""
Write-Host "Download complete."
Write-Host "Absence files: $absenceCount (expected 12)"
Write-Host "A&E files:     $activityCount (expected 12)"
Write-Host "Manifest:      $manifestPath"

if ($absenceCount -ne 12 -or $activityCount -ne 12) {
    throw "Expected 12 absence and 12 A&E files. Review the download output."
}

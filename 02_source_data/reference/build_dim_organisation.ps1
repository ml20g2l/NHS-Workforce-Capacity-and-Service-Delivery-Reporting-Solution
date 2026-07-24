param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

$profilePath = Join-Path $ProjectRoot "10_documentation\phase2_profile_summary.json"
$absenceFolder = Join-Path $ProjectRoot "02_source_data\raw\absence"
$outputPath = Join-Path $ProjectRoot "02_source_data\reference\dim_organisation.csv"

$profile = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json
$stableCodes = @($profile.joinCoverageSummary.stableAllThreeOrganisationCodes)
$allAbsenceRows = Get-ChildItem -LiteralPath $absenceFolder -Filter "*.csv" |
    Sort-Object Name |
    ForEach-Object { Import-Csv -LiteralPath $_.FullName }

$latestRows = Import-Csv -LiteralPath (
    Join-Path $absenceFolder "nhs_sickness_absence_2025-03.csv"
)

$referenceRows = foreach ($row in $latestRows) {
    if ($stableCodes -notcontains $row.ORG_CODE) {
        continue
    }

    $aliases = @(
        $allAbsenceRows |
            Where-Object { $_.ORG_CODE -eq $row.ORG_CODE } |
            Select-Object -ExpandProperty ORG_NAME -Unique
    )
    $isLondon = $row.NHSE_REGION_NAME -eq "London"
    $mappingStatus = if ($aliases.Count -gt 1) {
        "Approved alias history"
    } else {
        "Approved"
    }
    $reviewNote = if ($aliases.Count -gt 1) {
        "Published organisation name changed during the reporting window."
    } else {
        ""
    }

    [pscustomobject]@{
        OrganisationCode = $row.ORG_CODE
        CanonicalOrganisationName = $row.ORG_NAME
        OrganisationType = $row.ORG_TYPE
        RegionCode = $row.NHSE_REGION_CODE
        RegionName = $row.NHSE_REGION_NAME
        ICSCode = $row.ICS_CODE
        ICSName = $row.ICS_NAME
        ValidFromMonth = "2024-04-30"
        ValidToMonth = "2025-03-31"
        StableAllThreeMonths = $true
        InclusionFlag = $isLondon
        ReportingCohort = if ($isLondon) {
            "London stable 20-provider cohort"
        } else {
            "National stable reference"
        }
        ObservedAliases = $aliases -join "; "
        MappingStatus = $mappingStatus
        ReviewNote = $reviewNote
    }
}

$referenceRows |
    Sort-Object OrganisationCode |
    Export-Csv -LiteralPath $outputPath -NoTypeInformation -Encoding UTF8

Write-Host "Created organisation reference: $outputPath"
Write-Host "Reference rows: $($referenceRows.Count)"
Write-Host "Included London cohort: $(($referenceRows | Where-Object InclusionFlag).Count)"

param(
    [string]$WorkforceCsv = "04_processed_data/staging/workforce/workforce_staff_group_organisation_2025-03.csv",
    [string]$OrganisationReference = "02_source_data/reference/dim_organisation.csv",
    [string]$OutputCsv = "04_processed_data/reporting_sources/fact_workforce_report.csv",
    [datetime]$ReportingStartMonth = [datetime]"2024-04-01",
    [datetime]$ReportingEndMonth = [datetime]"2025-03-01",
    [int[]]$ReportingStaffGroupSortOrders = @(2, 19, 23, 28)
)

$ErrorActionPreference = "Stop"
$culture = [System.Globalization.CultureInfo]::InvariantCulture

$organisationByCode = @{}
Import-Csv -LiteralPath $OrganisationReference |
    Where-Object { $_.InclusionFlag -eq "True" } |
    ForEach-Object {
        $organisationByCode[$_.OrganisationCode.Trim().ToUpperInvariant()] = $_
    }

$grouped = @{}
Import-Csv -LiteralPath $WorkforceCsv | ForEach-Object {
    $sourceDate = [datetime]::ParseExact($_.Date, "yyyy-MM-dd", $culture)
    $reportingMonth = [datetime]::new($sourceDate.Year, $sourceDate.Month, 1)
    $organisationCode = $_.'Org Code'.Trim().ToUpperInvariant()
    $staffGroup = $_.'Staff Group'.Trim()
    $staffGroupSortOrder = [int]$_.'Staff Group Sort Order'
    $dataType = $_.'Data Type'.Trim().ToUpperInvariant()

    if (
        $reportingMonth -ge $ReportingStartMonth -and
        $reportingMonth -le $ReportingEndMonth -and
        $organisationByCode.ContainsKey($organisationCode) -and
        $staffGroup -and
        $staffGroup.ToLowerInvariant() -ne "total" -and
        $staffGroupSortOrder -in $ReportingStaffGroupSortOrders -and
        $dataType -in @("FTE", "HC")
    ) {
        $key = "{0}|{1}|{2}" -f $reportingMonth.ToString("yyyy-MM-dd"), $organisationCode, $staffGroup
        if (-not $grouped.ContainsKey($key)) {
            $reference = $organisationByCode[$organisationCode]
            $grouped[$key] = [ordered]@{
                MonthKey = ($reportingMonth.Year * 100) + $reportingMonth.Month
                ReportingMonth = $reportingMonth
                MonthLabel = $reportingMonth.ToString("MMM yyyy", $culture)
                OrganisationCode = $organisationCode
                OrganisationName = $reference.CanonicalOrganisationName
                OrganisationType = $reference.OrganisationType
                RegionName = $reference.RegionName
                StaffGroupSortOrder = $staffGroupSortOrder
                StaffGroup = $staffGroup
                FTE = 0.0
                Headcount = 0.0
            }
        }

        $measure = [double]::Parse($_.Total, $culture)
        if ($dataType -eq "FTE") {
            $grouped[$key].FTE += $measure
        } else {
            $grouped[$key].Headcount += $measure
        }
    }
}

$baseRows = $grouped.Values |
    ForEach-Object { [pscustomobject]$_ } |
    Sort-Object ReportingMonth, OrganisationCode, StaffGroupSortOrder, StaffGroup

$fteByKey = @{}
foreach ($row in $baseRows) {
    $fteByKey["{0}|{1}|{2}" -f $row.ReportingMonth.ToString("yyyy-MM-dd"), $row.OrganisationCode, $row.StaffGroup] = $row.FTE
}

$outputRows = foreach ($row in $baseRows) {
    $previousMonth = $row.ReportingMonth.AddMonths(-1)
    $previousKey = "{0}|{1}|{2}" -f $previousMonth.ToString("yyyy-MM-dd"), $row.OrganisationCode, $row.StaffGroup
    $fteChange = if ($fteByKey.ContainsKey($previousKey)) {
        $row.FTE - $fteByKey[$previousKey]
    } else {
        $null
    }

    [pscustomobject]@{
        MonthKey = $row.MonthKey
        ReportingMonth = $row.ReportingMonth.ToString("yyyy-MM-dd")
        MonthLabel = $row.MonthLabel
        OrganisationCode = $row.OrganisationCode
        OrganisationName = $row.OrganisationName
        OrganisationType = $row.OrganisationType
        RegionName = $row.RegionName
        StaffGroupSortOrder = $row.StaffGroupSortOrder
        StaffGroup = $row.StaffGroup
        FTE = [math]::Round($row.FTE, 5)
        Headcount = [math]::Round($row.Headcount, 5)
        FTEChange = if ($null -eq $fteChange) { $null } else { [math]::Round($fteChange, 5) }
    }
}

$outputDirectory = Split-Path -Parent $OutputCsv
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$outputRows | Export-Csv -LiteralPath $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Output ("Workforce report source rows: {0}" -f $outputRows.Count)
Write-Output ("Output: {0}" -f (Resolve-Path $OutputCsv))

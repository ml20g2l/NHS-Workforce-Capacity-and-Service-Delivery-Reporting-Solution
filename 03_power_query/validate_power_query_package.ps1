param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$mFolder = Join-Path $ProjectRoot "03_power_query\m"
$readmePath = Join-Path $ProjectRoot "03_power_query\README.md"
$referencePath = Join-Path $ProjectRoot "02_source_data\reference\dim_organisation.csv"

$expectedFiles = @(
    "00_fnGetParameter.pq",
    "01_pWorkforceFolder.pq",
    "02_pAbsenceFolder.pq",
    "03_pActivityFolder.pq",
    "04_pReportingStartMonth.pq",
    "05_pReportingEndMonth.pq",
    "06_pReferenceFolder.pq",
    "10_fnCleanOrganisationCode.pq",
    "11_fnParseDate.pq",
    "12_fnParseNumber.pq",
    "13_fnMonthFromFileName.pq",
    "14_fnMonthFromAEPeriod.pq",
    "15_fnGetSourceFiles.pq",
    "20_fnTransformWorkforceFile.pq",
    "21_fnTransformAbsenceFile.pq",
    "22_fnTransformActivityFile.pq",
    "30_stgWorkforceFiles.pq",
    "31_stgAbsenceFiles.pq",
    "32_stgServiceFiles.pq",
    "40_qryWorkforceClean.pq",
    "41_qryAbsenceClean.pq",
    "42_qryServiceActivityClean.pq",
    "50_qryPowerQueryExceptions.pq",
    "51_qryPowerQueryRefreshSummary.pq",
    "52_qrySourceFileRegister.pq",
    "53_dimOrganisation.pq",
    "60_dqWorkforceClassified.pq",
    "61_dqAbsenceClassified.pq",
    "62_dqServiceActivityClassified.pq",
    "63_dqRuleResults.pq",
    "64_dqReconciliation.pq"
)

$failures = [System.Collections.Generic.List[string]]::new()
$actualFiles = @(Get-ChildItem -LiteralPath $mFolder -Filter "*.pq" | Sort-Object Name)

if ($actualFiles.Count -ne $expectedFiles.Count) {
    $failures.Add("Expected $($expectedFiles.Count) M files; found $($actualFiles.Count).")
}

foreach ($fileName in $expectedFiles) {
    $filePath = Join-Path $mFolder $fileName
    if (-not (Test-Path -LiteralPath $filePath)) {
        $failures.Add("Missing M file: $fileName")
        continue
    }

    $content = Get-Content -LiteralPath $filePath -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        $failures.Add("Empty M file: $fileName")
    }
    $isParameterExpression = $content -match "IsParameterQuery\s*=\s*true"
    if (-not $isParameterExpression -and $content -notmatch "(?m)^in\s*$|(?m)^in\s+\S+") {
        $failures.Add("No final in expression detected: $fileName")
    }
}

foreach ($parameterFile in @(
    "01_pWorkforceFolder.pq",
    "02_pAbsenceFolder.pq",
    "03_pActivityFolder.pq",
    "04_pReportingStartMonth.pq",
    "05_pReportingEndMonth.pq",
    "06_pReferenceFolder.pq"
)) {
    $content = Get-Content -LiteralPath (Join-Path $mFolder $parameterFile) -Raw
    if ($content -notmatch "IsParameterQuery\s*=\s*true") {
        $failures.Add("$parameterFile is not marked as a native Power Query parameter.")
    }
    if ($content -match "fnGetParameter") {
        $failures.Add("$parameterFile still depends on fnGetParameter and may trigger Formula.Firewall.")
    }
}

$readme = Get-Content -LiteralPath $readmePath -Raw
foreach ($fileName in $expectedFiles) {
    if ($readme -notmatch [regex]::Escape($fileName)) {
        $failures.Add("README catalogue does not mention: $fileName")
    }
}

$requiredStagingTokens = @(
    "SourceModifiedTimestamp",
    "SourceSizeBytes",
    "FileVersionRank",
    "FileDisposition"
)
foreach ($stagingFile in @(
    "30_stgWorkforceFiles.pq",
    "31_stgAbsenceFiles.pq",
    "32_stgServiceFiles.pq"
)) {
    $content = Get-Content -LiteralPath (Join-Path $mFolder $stagingFile) -Raw
    foreach ($token in $requiredStagingTokens) {
        if ($content -notmatch [regex]::Escape($token)) {
            $failures.Add("$stagingFile does not retain $token.")
        }
    }
}

$sourceFilesFunction = Get-Content -LiteralPath (
    Join-Path $mFolder "15_fnGetSourceFiles.pq"
) -Raw
foreach ($compatibilityToken in @(
    "Record.FieldOrDefault",
    "Binary.Length",
    "SourceSizeBytes"
)) {
    if ($sourceFilesFunction -notmatch [regex]::Escape($compatibilityToken)) {
        $failures.Add("15_fnGetSourceFiles.pq is missing compatibility token $compatibilityToken.")
    }
}
if ($sourceFilesFunction -match '"Date modified",\s*"Size"') {
    $failures.Add("15_fnGetSourceFiles.pq still requires a top-level Size column.")
}

foreach ($classifiedFile in @(
    "60_dqWorkforceClassified.pq",
    "61_dqAbsenceClassified.pq",
    "62_dqServiceActivityClassified.pq"
)) {
    $content = Get-Content -LiteralPath (Join-Path $mFolder $classifiedFile) -Raw
    if ($content -notmatch '(?s)JoinDuplicateCounts\s*=\s*Table\.NestedJoin\(\s*ReferenceApplied,') {
        $failures.Add("$classifiedFile drops organisation mapping fields before duplicate-count expansion.")
    }
}

if (-not (Test-Path -LiteralPath $referencePath)) {
    $failures.Add("Missing organisation reference: $referencePath")
} else {
    $reference = @(Import-Csv -LiteralPath $referencePath)
    $included = @($reference | Where-Object { $_.InclusionFlag -eq "True" })
    if ($reference.Count -ne 148) {
        $failures.Add("Organisation reference should contain 148 rows; found $($reference.Count).")
    }
    if ($included.Count -ne 20) {
        $failures.Add("London reporting cohort should contain 20 rows; found $($included.Count).")
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Power Query package validation: FAIL"
    $failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host "Power Query package validation: PASS"
Write-Host "M queries: $($expectedFiles.Count)"
Write-Host "Organisation reference rows: 148"
Write-Host "London reporting cohort: 20"
Write-Host "Static package checks passed. Excel runtime refresh remains required."

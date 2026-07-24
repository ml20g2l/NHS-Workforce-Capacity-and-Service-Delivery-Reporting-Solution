param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$sourceZip = Join-Path $resolvedProjectRoot "02_source_data\raw\workforce\nhs_workforce_statistics_2025-03_csv.zip"
$destinationFolder = Join-Path $resolvedProjectRoot "04_processed_data\staging\workforce"
$destinationFile = Join-Path $destinationFolder "workforce_staff_group_organisation_2025-03.csv"
$manifestFile = Join-Path $destinationFolder "workforce_extract_manifest.csv"
$expectedEntryName = "NHS Workforce Statistics, March 2025 Staff Group and Organisation.csv"

if (-not (Test-Path -LiteralPath $sourceZip -PathType Leaf)) {
    throw "Workforce ZIP not found: $sourceZip"
}

New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($sourceZip)

try {
    $matchingEntries = @(
        $archive.Entries | Where-Object {
            [System.IO.Path]::GetFileName($_.FullName) -eq $expectedEntryName
        }
    )

    if ($matchingEntries.Count -ne 1) {
        throw "Expected exactly one '$expectedEntryName' entry; found $($matchingEntries.Count)."
    }

    [System.IO.Compression.ZipFileExtensions]::ExtractToFile(
        $matchingEntries[0],
        $destinationFile,
        $true
    )
}
finally {
    $archive.Dispose()
}

$manifestRow = [pscustomobject]@{
    SourceZip        = $sourceZip
    SourceZipSHA256  = (Get-FileHash -LiteralPath $sourceZip -Algorithm SHA256).Hash
    ExtractedEntry   = $expectedEntryName
    DestinationFile  = $destinationFile
    OutputSHA256     = (Get-FileHash -LiteralPath $destinationFile -Algorithm SHA256).Hash
    OutputBytes      = (Get-Item -LiteralPath $destinationFile).Length
    ExtractedAtUTC   = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
}

$manifestRow | Export-Csv -LiteralPath $manifestFile -NoTypeInformation -Encoding UTF8

Write-Host "Workforce extract ready:"
Write-Host $destinationFile
Write-Host "Manifest:"
Write-Host $manifestFile

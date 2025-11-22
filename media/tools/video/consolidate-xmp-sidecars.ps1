[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Root = 'D:\Immich\library\library\admin',
    [int]$ParallelJobs = ([Environment]::ProcessorCount - 1),
    [switch]$PreviewOnly
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
if ($ParallelJobs -lt 1) { $ParallelJobs = 1 }
if (-not (Test-Path $Root)) { throw "Root not found: $Root" }

$fields = @(
    'XMP:DateTimeOriginal',
    'XMP:CreateDate',
    'XMP:ModifyDate',
    'XMP:Rating',
    'XMP:Label',
    'XMP:Subject',
    'XMP:HierarchicalSubject'
)

$candidates = Get-ChildItem -Path $Root -Filter '*.xmp' -Recurse -File |
    Where-Object { $_.Name -match '\.[^.]+\.(xmp)$' }

if ($candidates.Count -eq 0) {
    Write-Console "No extension-suffixed XMP files found under $Root." -ForegroundColor Green
    return
}

Write-Console "Found $($candidates.Count) extension-based XMP files. Consolidating…" -ForegroundColor Cyan

$results = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
$preview = $PreviewOnly.IsPresent

$candidates | ForEach-Object -Parallel {
    param($fields,$preview,$results)

    $extFile = $_
    $stdPath = $extFile.FullName -replace '\.[^.]+\.xmp$','.xmp'

    if ($preview) {
        $results.Add("Would normalize $($extFile.FullName) -> $stdPath")
        return
    }

    if (-not (Test-Path $stdPath)) {
        Rename-Item -LiteralPath $extFile.FullName -NewName $stdPath
        $results.Add("Renamed $($extFile.FullName) → $stdPath")
        return
    }

    foreach ($field in $fields) {
        $extValue = (exiftool -s3 -$field $extFile.FullName) 2>$null
        if ([string]::IsNullOrWhiteSpace($extValue)) { continue }

        $stdValue = (exiftool -s3 -$field $stdPath) 2>$null
        if ($field -match 'Subject') {
            $stdList = @()
            if ($stdValue) { $stdList = $stdValue -split ';' }
            $extList = $extValue -split ';'
            $merged = ($stdList + $extList | Where-Object { $_ } | Sort-Object -Unique) -join ';'
            exiftool -quiet -overwrite_original -sep ';' -$field="$merged" $stdPath | Out-Null
        } elseif ([string]::IsNullOrWhiteSpace($stdValue)) {
            exiftool -quiet -overwrite_original -$field="$extValue" $stdPath | Out-Null
        }
    }

    Remove-Item -LiteralPath $extFile.FullName -Force
    $results.Add("Merged metadata from $($extFile.Name) into $(Split-Path $stdPath -Leaf)")
} -ThrottleLimit $ParallelJobs -ArgumentList ($fields,$preview,$results)

if ($results.Count -gt 0) {
    Write-Console "Consolidation complete:" -ForegroundColor Green
    $results | Sort-Object | Select-Object -First 40
    if ($results.Count -gt 40) { Write-Console "…and $($results.Count - 40) more." -ForegroundColor Gray }
}

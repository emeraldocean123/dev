<#
.SYNOPSIS
    Import XMP keywords from Mylio sidecar files into DigiKam database

.DESCRIPTION
    This script reads keywords from XMP sidecar files (created by Mylio) and imports
    them into DigiKam's SQLite database. DigiKam doesn't natively read XMP sidecars
    for video and HEIF files, so this script bridges that gap.

.PARAMETER LibraryPath
    Path to photo library (default: D:\Immich\library\library\admin)

.PARAMETER DatabasePath
    Path to DigiKam database (default: D:\Immich\library\library\digikam4.db)

.PARAMETER ExifToolPath
    Path to ExifTool executable (default: D:\Files\Programs-Portable\ExifTool\exiftool.exe)

.PARAMETER BackupDirectory
    Directory where timestamped DigiKam backups will be written (default: D:\Immich\backup\db)

.PARAMETER DryRun
    If specified, shows what would be imported without making changes

.EXAMPLE
    .\import-xmp-keywords-to-digikam.ps1
    Import all XMP keywords into DigiKam database

.EXAMPLE
    .\import-xmp-keywords-to-digikam.ps1 -DryRun
    Preview what would be imported without making changes

.NOTES
    Author: Claude Code
    Date: November 17, 2025
    Version: 1.2
#>

[CmdletBinding()]
param(
[string]$LibraryPath = "D:\Immich\library\library\admin",
[string]$DatabasePath = "D:\Immich\library\library\digikam4.db",
[string]$ExifToolPath = "D:\Files\Programs-Portable\ExifTool\exiftool.exe",
[string]$SQLiteDllPath = "C:\Windows\Microsoft.NET\assembly\GAC_64\System.Data.SQLite\v4.0_1.0.118.0__db937bc2d44ff139\System.Data.SQLite.dll",
[string]$SQLiteCliPath = (Join-Path $HOME 'bin/sqlite3.exe'),
[string]$BackupDirectory = "D:\Immich\backup\db",
[switch]$DryRun
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
$ErrorActionPreference = 'Stop'

function Write-Console {
    param(
        [Parameter(Position = 0)]
        [string]$Message = '',
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::Gray,
        [System.ConsoleColor]$BackgroundColor,
        [switch]$NoNewline
    )

    $rawUI = $null
    $previousForeground = $null
    $previousBackground = $null

    try {
        if ($Host -and $Host.UI -and $Host.UI.RawUI) {
            $rawUI = $Host.UI.RawUI
            $previousForeground = $rawUI.ForegroundColor
            $previousBackground = $rawUI.BackgroundColor
            $rawUI.ForegroundColor = $ForegroundColor
            if ($PSBoundParameters.ContainsKey('BackgroundColor')) {
                $rawUI.BackgroundColor = $BackgroundColor
            }
        }

        if ($NoNewline -and $Host -and $Host.UI) {
            $Host.UI.Write($Message)
        } else {
            Write-Information -MessageData $Message -InformationAction Continue
        }
    } catch {
        Write-Information -MessageData $Message -InformationAction Continue
    } finally {
        if ($rawUI -and $null -ne $previousForeground) {
            try {
                $rawUI.ForegroundColor = $previousForeground
            } catch {
                Write-Verbose "Unable to reset foreground color: $($_.Exception.Message)"
            }
        }

        if ($rawUI -and $PSBoundParameters.ContainsKey('BackgroundColor') -and $null -ne $previousBackground) {
            try {
                $rawUI.BackgroundColor = $previousBackground
            } catch {
                Write-Verbose "Unable to reset background color: $($_.Exception.Message)"
            }
        }
    }
}

Write-Console "Validating paths..." -ForegroundColor Cyan
if (-not (Test-Path -LiteralPath $LibraryPath)) {
    throw "Library path not found: $LibraryPath"
}

if (-not (Test-Path -LiteralPath $DatabasePath)) {
    throw "DigiKam database not found: $DatabasePath"
}

if (-not (Test-Path -LiteralPath $BackupDirectory)) {
    New-Item -Path $BackupDirectory -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $ExifToolPath)) {
    throw "ExifTool not found: $ExifToolPath"
}

$LibraryPath = (Resolve-Path -LiteralPath $LibraryPath).Path
$DatabasePath = (Resolve-Path -LiteralPath $DatabasePath).Path
$ExifToolPath = (Resolve-Path -LiteralPath $ExifToolPath).Path

if ($SQLiteCliPath -and (Test-Path -LiteralPath $SQLiteCliPath)) {
    $SQLiteCliPath = (Resolve-Path -LiteralPath $SQLiteCliPath).Path
}

Write-Console "Loading SQLite support..." -ForegroundColor Cyan
$useSQLiteCommand = $false
$sqliteAssemblyLoaded = $false
$sqliteCliExecutable = $null

if ($SQLiteDllPath -and (Test-Path -LiteralPath $SQLiteDllPath)) {
    try {
        Add-Type -Path $SQLiteDllPath -ErrorAction Stop
        if (([System.Management.Automation.PSTypeName]'System.Data.SQLite.SQLiteConnection').Type) {
            $sqliteAssemblyLoaded = $true
            Write-Console "Loaded System.Data.SQLite from $SQLiteDllPath" -ForegroundColor Green
        }
    } catch {
        Write-Console "Failed to load System.Data.SQLite: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Console "System.Data.SQLite DLL not found at $SQLiteDllPath" -ForegroundColor Yellow
}

if (-not $sqliteAssemblyLoaded) {
    if ($SQLiteCliPath -and (Test-Path -LiteralPath $SQLiteCliPath)) {
        $sqliteCliExecutable = $SQLiteCliPath
    } else {
        $sqliteCmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
        if ($sqliteCmd) {
            $sqliteCliExecutable = $sqliteCmd.Source
        }
    }

    if ($sqliteCliExecutable) {
        Write-Console "Falling back to sqlite3 CLI for database access ($sqliteCliExecutable)" -ForegroundColor Yellow
        $useSQLiteCommand = $true
    } else {
        throw "SQLite support unavailable: install System.Data.SQLite (set -SQLiteDllPath) or provide sqlite3.exe via -SQLiteCliPath / PATH."
    }
} else {
    Write-Console "Using System.Data.SQLite .NET provider" -ForegroundColor Green
}

$albumRootPath = Split-Path -Path $LibraryPath -Parent
if (-not $albumRootPath) {
    throw "Unable to determine album root from $LibraryPath"
}

$albumRootFull = [System.IO.Path]::GetFullPath($albumRootPath)
if ($albumRootFull.EndsWith('\')) {
    $script:AlbumRootNormalized = $albumRootFull.TrimEnd('\')
    $script:AlbumRootPrefix = $albumRootFull
} else {
    $script:AlbumRootNormalized = $albumRootFull
    $script:AlbumRootPrefix = "$albumRootFull\"
}

$script:FolderCache = @{}

function Invoke-SQLiteQuery {
    param(
        [string]$Query,
        [switch]$NonQuery
    )

    if ($useSQLiteCommand) {
        if ($NonQuery) {
            $Query | & $sqliteCliExecutable $DatabasePath | Out-Null
            return
        }
        return & $sqliteCliExecutable $DatabasePath $Query
    }

    $connection = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$DatabasePath")
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        if ($NonQuery) {
            $command.ExecuteNonQuery() | Out-Null
            return
        }

        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($command)
        $dataSet = New-Object System.Data.DataSet
        $adapter.Fill($dataSet) | Out-Null
        return $dataSet.Tables[0]
    } finally {
        $connection.Close()
    }
}

$SqlBatchSize = 5000
function Initialize-SqlBatch {
    $script:SqlBatchStatements = New-Object System.Collections.Generic.List[string]
    $script:SqlBatchStatements.Add('BEGIN TRANSACTION;')
    $script:SqlBatchCount = 0
}

Initialize-SqlBatch

function Invoke-SqlBatch {
    if ($script:SqlBatchCount -le 0) {
        Initialize-SqlBatch
        return
    }

    $script:SqlBatchStatements.Add('COMMIT;')
    $batchSql = $script:SqlBatchStatements -join "`n"
    Invoke-SQLiteQuery -Query $batchSql -NonQuery | Out-Null
    Initialize-SqlBatch
}

function Convert-ToRelativeAlbumPath {
    param([string]$FullPath)

    $absolute = [System.IO.Path]::GetFullPath($FullPath)
    if ($absolute.StartsWith($script:AlbumRootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $absolute.Substring($script:AlbumRootPrefix.Length)
    } elseif ($absolute.Equals($script:AlbumRootNormalized, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = ''
    } else {
        return $null
    }

    $relative = $relative.TrimStart('\', '/')
    if ([string]::IsNullOrEmpty($relative)) {
        return '/'
    }

    return '/' + $relative.Replace('\', '/').Replace('//', '/')
}

function Get-ImageIdForFile {
    param(
        [string]$RelativeFolder,
        [string]$BaseName
    )

    if (-not $script:FolderCache.ContainsKey($RelativeFolder)) {
        $script:FolderCache[$RelativeFolder] = @{}
    }

    $folderEntry = $script:FolderCache[$RelativeFolder]
    if ($folderEntry.ContainsKey($BaseName)) {
        return $folderEntry[$BaseName]
    }

    $safeFolder = $RelativeFolder.Replace("'", "''")
    $safeBase = $BaseName.Replace("'", "''")
    $folderQuery = @"
SELECT Images.name, Images.id
FROM Images
INNER JOIN Albums ON Images.album = Albums.id
WHERE Albums.relativePath = '$safeFolder' AND Images.name LIKE '$safeBase.%';
"@

    $candidates = @()
    $folderResult = Invoke-SQLiteQuery -Query $folderQuery
    if ($useSQLiteCommand) {
        foreach ($line in $folderResult) {
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }
            $parts = $line -split '\|'
            if ($parts.Length -ge 2) {
                $candidates += [PSCustomObject]@{ Name = $parts[0]; Id = [int]$parts[1] }
            }
        }
    } elseif ($folderResult) {
        foreach ($row in $folderResult) {
            $candidates += [PSCustomObject]@{ Name = $row.name; Id = [int]$row.id }
        }
    }

    $resolvedId = $null
    if ($candidates.Count -eq 1) {
        $resolvedId = $candidates[0].Id
    } elseif ($candidates.Count -gt 1) {
        $priorityExtensions = @('mp4','mov','m4v','avi','mpg','mpeg','hevc','heic','heif','jpg','jpeg','png','tif','tiff')
        foreach ($ext in $priorityExtensions) {
            $match = $candidates | Where-Object { $_.Name.EndsWith(".$ext", [System.StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
            if ($match) {
                $resolvedId = $match.Id
                break
            }
        }

        if (-not $resolvedId) {
            $resolvedId = $candidates[0].Id
        }
    }

    $folderEntry[$BaseName] = $resolvedId
    return $resolvedId
}

# Check if DigiKam is running
$digikamProcess = Get-Process -Name 'digikam' -ErrorAction SilentlyContinue
if ($digikamProcess) {
    Write-Console 'WARNING: DigiKam is currently running!' -ForegroundColor Yellow
    Write-Console 'Please close DigiKam before running this script to avoid database corruption.' -ForegroundColor Yellow
    $response = Read-Host 'Continue anyway? (yes/no)'
    if ($response -ne 'yes') {
        Write-Console 'Exiting...' -ForegroundColor Cyan
        return
    }
}

# Create backup of database
if (-not $DryRun) {
    $databaseFileName = Split-Path -Path $DatabasePath -Leaf
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
    $backupPath = Join-Path $BackupDirectory "$databaseFileName.backup-$timestamp"
    Write-Console "Creating database backup: $backupPath" -ForegroundColor Cyan
    Copy-Item -LiteralPath $DatabasePath -Destination $backupPath -Force
    Write-Console 'Backup created successfully' -ForegroundColor Green
}

Write-Console 'Scanning for XMP files in library...' -ForegroundColor Cyan
$xmpCount = (Get-ChildItem -Path $LibraryPath -Filter '*.xmp' -Recurse -File | Measure-Object).Count
Write-Console "Found $xmpCount XMP files" -ForegroundColor Green

Write-Console 'Extracting keywords from XMP files (this may take a few minutes)...' -ForegroundColor Cyan
$exifArgs = @(
    '-api','largefilesupport=1',
    '-charset','filename=UTF8',
    '-Subject',
    '-FileName',
    '-Directory',
    '-FilePath',
    '-T',
    '-sep','||',
    '-ext','xmp',
    '-r',$LibraryPath
)

$filesWithKeywords = 0
$totalKeywords = 0
$dryRunSamples = New-Object System.Collections.Generic.List[object]
$sampleLimit = 10
$importedCount = 0
$skippedCount = 0
$errorCount = 0

Write-Console 'Looking up tag IDs...' -ForegroundColor Cyan
$tagQuery = "SELECT id, name FROM Tags WHERE name IN ('Follett', 'Joseph', 'Nok');"
$tagResult = Invoke-SQLiteQuery -Query $tagQuery

$tagMap = @{}
if ($useSQLiteCommand) {
    foreach ($line in $tagResult) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        $parts = $line -split '\|'
        if ($parts.Length -eq 2) {
            $tagMap[$parts[1]] = [int]$parts[0]
        }
    }
} elseif ($tagResult) {
    foreach ($row in $tagResult) {
        $tagMap[$row.name] = [int]$row.id
    }
}

if ($tagMap.Count -eq 0) {
    throw 'No tags found! Please create Follett, Joseph, and Nok tags in DigiKam first.'
}

Write-Console "Found tags: $($tagMap.Keys -join ', ')" -ForegroundColor Green

& $ExifToolPath $exifArgs | ForEach-Object {
    $xmpFileName = $null
    try {
        $columns = $_ -split "`t"
        if ($columns.Count -lt 4) {
            return
        }

        $subjectRaw = $columns[0]
        if ([string]::IsNullOrWhiteSpace($subjectRaw)) {
            return
        }

        $keywords = $subjectRaw -split '\|\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        if ($keywords.Count -eq 0) {
            return
        }

        $filesWithKeywords++
        $totalKeywords += $keywords.Count

        $xmpFileName = $columns[1]
        $mediaBaseName = [System.IO.Path]::GetFileNameWithoutExtension($xmpFileName)
        if ([string]::IsNullOrWhiteSpace($mediaBaseName)) {
            $skippedCount++
            return
        }

        $filePathValue = $columns[3]
        if ([string]::IsNullOrWhiteSpace($filePathValue)) {
            $skippedCount++
            return
        }

        $mediaDirectory = [System.IO.Path]::GetDirectoryName($filePathValue)
        if (-not $mediaDirectory) {
            $skippedCount++
            return
        }

        $mediaDirectory = [System.IO.Path]::GetFullPath($mediaDirectory)
        $relativeFolder = Convert-ToRelativeAlbumPath -FullPath $mediaDirectory
        if (-not $relativeFolder) {
            $skippedCount++
            return
        }

        if ($DryRun -and $dryRunSamples.Count -lt $sampleLimit) {
            $displayPath = "$relativeFolder/$mediaBaseName.*" -replace '//','/'
            $dryRunSamples.Add([PSCustomObject]@{ File = $displayPath; Keywords = $keywords -join ', ' })
        }

        $imageId = Get-ImageIdForFile -RelativeFolder $relativeFolder -BaseName $mediaBaseName
        if (-not $imageId) {
            $skippedCount++
            return
        }

        if ($DryRun) {
            return
        }

        foreach ($keyword in $keywords) {
            if (-not $tagMap.ContainsKey($keyword)) {
                continue
            }

            $tagId = $tagMap[$keyword]
            $script:SqlBatchStatements.Add("INSERT OR IGNORE INTO ImageTags (imageid, tagid) VALUES ($imageId, $tagId);")
            $script:SqlBatchCount++
            $importedCount++

            if ($script:SqlBatchCount -ge $SqlBatchSize) {
                Invoke-SqlBatch
            }
        }

        if ($importedCount -gt 0 -and ($importedCount % 500 -eq 0)) {
            Write-Console '.' -ForegroundColor DarkGray -NoNewline
        }
    } catch {
        $errorCount++
        $displayName = if ($xmpFileName) { $xmpFileName } else { '<unknown>' }
        Write-Console "Error processing $displayName : $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

if ($DryRun) {
    Write-Console "`n=== DRY RUN MODE - No changes will be made ===`n" -ForegroundColor Yellow
    if ($dryRunSamples.Count -gt 0) {
        Write-Console 'Sample of files with keywords:' -ForegroundColor Cyan
        foreach ($entry in $dryRunSamples) {
            Write-Console "  $($entry.File): $($entry.Keywords)" -ForegroundColor Gray
        }
    } else {
        Write-Console 'No files with keywords were detected in this sample.' -ForegroundColor Yellow
    }

    Write-Console "Total files with keywords : $filesWithKeywords" -ForegroundColor Green
    Write-Console "Total keywords detected    : $totalKeywords" -ForegroundColor Green
    Write-Console "Possible database matches  : $($filesWithKeywords - $skippedCount)" -ForegroundColor Green
    Write-Console "`nRun the script without -DryRun to import these keywords." -ForegroundColor Cyan
    return
}

Invoke-SqlBatch
Write-Console ''
Write-Console '=== Import Complete ===' -ForegroundColor Green
Write-Console "Imported: $importedCount keyword assignments" -ForegroundColor Cyan
Write-Console "Skipped: $skippedCount files (not in database path scope)" -ForegroundColor Yellow
Write-Console "Errors: $errorCount" -ForegroundColor Yellow

Write-Console "`nNext steps:" -ForegroundColor Cyan
Write-Console "1. Open DigiKam" -ForegroundColor Gray
Write-Console "2. Search for 'Follett', 'Joseph', or 'Nok' tags" -ForegroundColor Gray
Write-Console '3. Videos and HEIF files should now appear in results' -ForegroundColor Gray
Write-Console "`nDone!" -ForegroundColor Green

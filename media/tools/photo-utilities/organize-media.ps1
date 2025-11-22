# Unified Media Organizer (Lite)
# Renames and Organizes media into YYYY/MM structure
# Matches logic of media-manager.py (SHA256 hash) without Python dependencies
# Location: media/tools/photo-utilities/organize-media.ps1

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$SourcePath,

    [Parameter(Mandatory=$false, Position=1)]
    [string]$DestinationPath,

    [switch]$Organize, # If set, moves to YYYY/MM structure. If not, renames in place.
    [switch]$Copy,     # Copy instead of Move (Safety mode)
    [switch]$DryRun
)

# =============================================================================
# CONFIGURATION LOADING
# =============================================================================
$devRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
$configPath = Join-Path $devRoot ".config\homelab.settings.json"
$config = $null

if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
}

# Default Paths
if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    $SourcePath = if ($config.Paths.MediaWorkspace) { $config.Paths.MediaWorkspace } else { $PWD }
}
if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
    # Default to source if not organizing, otherwise try config
    if ($Organize) {
        $DestinationPath = if ($config.Paths.MylioCatalog) { $config.Paths.MylioCatalog } else { Join-Path $SourcePath "Organized" }
    } else {
        $DestinationPath = $SourcePath
    }
}

# Import Utilities
$libPath = Join-Path $devRoot "lib\utils.ps1"
if (Test-Path $libPath) { . $libPath } else { function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor } }

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

function Get-FileHashSHA256Short {
    param([string]$FilePath)
    try {
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $stream = [System.IO.File]::OpenRead($FilePath)
        $hashBytes = $sha256.ComputeHash($stream)
        $stream.Close()
        # Convert to hex, remove dashes, take first 8 chars, lowercase
        return ([BitConverter]::ToString($hashBytes) -replace '-', '').Substring(0, 8).ToLower()
    } catch {
        return "00000000"
    }
}

function Get-SanitizedCameraName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return "unknown" }
    $Name = $Name.ToLower() -replace '[^\w\d]+', '_'
    $Name = $Name -replace '([a-z])(\d)', '$1_$2' -replace '(\d)([a-z])', '$1_$2'
    return $Name.Trim('_').Substring(0, [Math]::Min($Name.Length, 30))
}

# =============================================================================
# MAIN LOGIC
# =============================================================================

Write-Console "Media Organizer (PowerShell Native)" -ForegroundColor Cyan
Write-Console "Source:      $SourcePath" -ForegroundColor Gray
Write-Console "Destination: $DestinationPath" -ForegroundColor Gray
Write-Console "Mode:        $(if ($Organize) { "Organize (YYYY/MM)" } else { "Rename Only" })" -ForegroundColor Gray
Write-Console "Action:      $(if ($Copy) { "Copy" } else { "Move" })" -ForegroundColor Gray
Write-Console "Hashing:     SHA256 (First 8 chars)" -ForegroundColor Magenta
Write-Console ""

if (-not (Test-Path $SourcePath)) { Write-Console "ERROR: Source not found" -ForegroundColor Red; exit 1 }
if ($Organize -and -not (Test-Path $DestinationPath) -and -not $DryRun) { New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null }

$files = Get-ChildItem -Path $SourcePath -Recurse -File -Include *.jpg,*.jpeg,*.png,*.heic,*.mp4,*.mov,*.avi
$total = $files.Count
$count = 0

foreach ($file in $files) {
    $count++
    $progress = "[{0:D3}/{1:D3}]" -f $count, $total

    # 1. Get Metadata (Fastest: Name -> Basic EXIF)
    # Note: PowerShell native EXIF is hard. Using ExifTool wrapper pattern if available is best.
    # For "Lite" version, we parse filename if it matches pattern, else creation date.

    $date = $file.CreationTime
    $make = "device"
    $model = "model"

    # Try to parse standardized name first (Fastest)
    if ($file.Name -match '^(\d{4})-(\d{2})-(\d{2})-(\d{6})-(.+?)-(.+?)-[a-f0-9]{8}\.\w+$') {
        # Already standardized!
        $date = Get-Date -Date "$($matches[1])-$($matches[2])-$($matches[3]) $($matches[4].Substring(0,2)):$($matches[4].Substring(2,2)):$($matches[4].Substring(4,2))"
        $make = $matches[5]
        $model = $matches[6]
        $hash = $matches[0].Split('-')[-1].Split('.')[0] # Extract hash from name
    } else {
        # Needs processing
        # Use ExifTool if available for accuracy
        if (Get-Command exiftool -ErrorAction SilentlyContinue) {
            $meta = exiftool -j -fast2 -DateTimeOriginal -CreateDate -Make -Model $file.FullName | ConvertFrom-Json
            if ($meta -and $meta.Count -gt 0) {
                $metaObj = $meta[0]
                $dateStr = if ($metaObj.DateTimeOriginal) { $metaObj.DateTimeOriginal } else { $metaObj.CreateDate }
                if ($dateStr) {
                    try { $date = [DateTime]::ParseExact($dateStr.Substring(0,19), "yyyy:MM:dd HH:mm:ss", $null) } catch {}
                }
                if ($metaObj.Make) { $make = Get-SanitizedCameraName $metaObj.Make }
                if ($metaObj.Model) { $model = Get-SanitizedCameraName $metaObj.Model }
            }
        }
        # Compute Hash (Expensive but necessary)
        $hash = Get-FileHashSHA256Short -FilePath $file.FullName
    }

    # 2. Construct New Name
    $dateStr = $date.ToString("yyyy-MM-dd-HHmmss")
    $ext = $file.Extension.ToLower()
    $newName = "$dateStr-$make-$model-$hash$ext"

    # 3. Determine Target Folder
    if ($Organize) {
        $year = $date.ToString("yyyy")
        $month = $date.ToString("MM")
        $targetDir = Join-Path $DestinationPath "$year\$month"
    } else {
        $targetDir = $file.DirectoryName
    }

    $targetPath = Join-Path $targetDir $newName

    # 4. Execute
    if ($file.FullName -eq $targetPath) {
        Write-Console "$progress Skip: Already correct" -ForegroundColor DarkGray
        continue
    }

    if ($DryRun) {
        Write-Console "$progress [DRY] $targetPath" -ForegroundColor Yellow
    } else {
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }

        if (Test-Path $targetPath) {
            Write-Console "$progress Skip: Destination exists" -ForegroundColor Red
            continue
        }

        if ($Copy) {
            Copy-Item -Path $file.FullName -Destination $targetPath
            Write-Console "$progress Copied -> $year/$month/$newName" -ForegroundColor Green
        } else {
            Move-Item -Path $file.FullName -Destination $targetPath
            Write-Console "$progress Moved -> $year/$month/$newName" -ForegroundColor Green
        }

        # Handle Sidecar
        $xmp = "$($file.FullName).xmp"
        if (Test-Path $xmp) {
            $xmpDest = "$targetPath.xmp"
            if ($Copy) { Copy-Item $xmp $xmpDest } else { Move-Item $xmp $xmpDest }
        }
    }
}

Write-Console ""
Write-Console "Processing complete: $count files" -ForegroundColor Green
Write-Console ""

# Analyze Mylio crash dump file

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

$dumpFile = "C:\Users\josep\.Mylio_Catalog\crashpad\reports\7e4c5ad1-3a92-4b20-b377-23fce253f6ef.dmp"

Write-Console "=== Mylio Crash Dump Analysis ===" -ForegroundColor Cyan
Write-Console ""
Write-Console "Crash dump file: $dumpFile" -ForegroundColor Yellow
Write-Console "Created: 11/2/2025 1:42:51 PM" -ForegroundColor Gray
Write-Console "Size: 23.95 MB" -ForegroundColor Gray
Write-Console ""

Write-Console "=== Extracting Readable Strings ===" -ForegroundColor Cyan
Write-Console ""

# Read binary file and extract ASCII strings (minimum 10 characters)
$bytes = [System.IO.File]::ReadAllBytes($dumpFile)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)

# Look for error-related strings
$errorPatterns = @(
    "exception",
    "error",
    "crash",
    "fault",
    "violation",
    "abort",
    "assert",
    "failed",
    "stack trace",
    "breakpoint",
    "corrupted",
    "0xC0000005",  # Access violation
    "0xC000000D",  # Invalid parameter
    "0x80000003"   # Breakpoint
)

Write-Console "Searching for error indicators..." -ForegroundColor Yellow
Write-Console ""

$findings = @{}

foreach ($pattern in $errorPatterns) {
    # Case-insensitive search
    if ($text -match "(?i)$pattern") {
        # Extract context around the match (100 chars before and after)
        $matches = [regex]::Matches($text, "(?i).{0,100}$pattern.{0,100}")

        if ($matches.Count -gt 0) {
            $findings[$pattern] = @()

            foreach ($match in $matches | Select-Object -First 5) {
                $context = $match.Value -replace '[^\x20-\x7E]', ' ' -replace '\s+', ' '
                if ($context.Length -gt 10) {
                    $findings[$pattern] += $context.Trim()
                }
            }
        }
    }
}

if ($findings.Count -gt 0) {
    foreach ($key in $findings.Keys) {
        if ($findings[$key].Count -gt 0) {
            Write-Console "Found '$key':" -ForegroundColor Red
            foreach ($context in $findings[$key] | Select-Object -Unique) {
                Write-Console "  $context" -ForegroundColor Yellow
            }
            Write-Console ""
        }
    }
} else {
    Write-Console "No obvious error strings found in dump" -ForegroundColor Green
}

Write-Console ""

# Look for module names (DLLs)
Write-Console "=== Loaded Modules ===" -ForegroundColor Cyan
Write-Console ""

$dllMatches = [regex]::Matches($text, "[a-zA-Z0-9_\-]+\.dll")
$uniqueDlls = $dllMatches | ForEach-Object { $_.Value.ToLower() } | Select-Object -Unique | Sort-Object

if ($uniqueDlls) {
    Write-Console "Detected DLLs (first 30):" -ForegroundColor Yellow
    $uniqueDlls | Select-Object -First 30 | ForEach-Object {
        Write-Console "  $_" -ForegroundColor Gray
    }
    Write-Console ""
    Write-Console "Total unique DLLs found: $($uniqueDlls.Count)" -ForegroundColor Cyan
}

Write-Console ""

# Look for file paths
Write-Console "=== File Paths in Dump ===" -ForegroundColor Cyan
Write-Console ""

$pathMatches = [regex]::Matches($text, "[A-Z]:\\[^`r`n`"<>|]{5,200}")
$uniquePaths = $pathMatches | ForEach-Object { $_.Value } |
    Where-Object { $_ -match '\.(exe|dll|db|log|xmp|jpg|png|mp4)' } |
    Select-Object -Unique | Sort-Object

if ($uniquePaths) {
    Write-Console "Detected file paths (first 20):" -ForegroundColor Yellow
    $uniquePaths | Select-Object -First 20 | ForEach-Object {
        Write-Console "  $_" -ForegroundColor Gray
    }
    Write-Console ""
    Write-Console "Total unique paths found: $($uniquePaths.Count)" -ForegroundColor Cyan
}

Write-Console ""

# Check if WinDbg or debugger info available
Write-Console "=== Debugging Recommendation ===" -ForegroundColor Cyan
Write-Console ""
Write-Console "For detailed crash analysis, use:" -ForegroundColor Yellow
Write-Console "  1. Windows Debugger (WinDbg) - from Microsoft Store or Windows SDK" -ForegroundColor Gray
Write-Console "  2. Visual Studio Debugger" -ForegroundColor Gray
Write-Console "  3. Send crash dump to Mylio support for analysis" -ForegroundColor Gray
Write-Console ""
Write-Console "Crash occurred on: November 2, 2025 at 1:42:51 PM" -ForegroundColor Yellow
Write-Console "Days since crash: $((Get-Date) - (Get-Date '2025-11-02 13:42:51')).Days days ago" -ForegroundColor Gray
Write-Console ""

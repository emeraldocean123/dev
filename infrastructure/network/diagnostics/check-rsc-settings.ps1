# Check RSC and EEE Settings for CalDigit Ethernet
# Created: October 23, 2025
# Purpose: Verify Recv Segment Coalescing and Energy Efficient Ethernet are disabled

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}

Write-Console "`n=== CalDigit Ethernet Adapter Settings Check ===" -ForegroundColor Cyan
Write-Console "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Gray

# Get all advanced properties for Ethernet adapter
$adapter = Get-NetAdapter -Name "Ethernet" -ErrorAction SilentlyContinue

if (-not $adapter) {
    Write-Console "ERROR: Ethernet adapter not found!" -ForegroundColor Red
    Write-Console "CalDigit hub may be disconnected.`n" -ForegroundColor Yellow
    exit 1
}

Write-Console "Adapter: $($adapter.InterfaceDescription)" -ForegroundColor Green
Write-Console "Status: $($adapter.Status)" -ForegroundColor Green
Write-Console "Link Speed: $($adapter.LinkSpeed)`n" -ForegroundColor Green

# Check critical settings
$settings = @{
    "Recv Segment Coalescing (IPv4)" = "*RscIPv4"
    "Recv Segment Coalescing (IPv6)" = "*RscIPv6"
    "Energy Efficient Ethernet" = "EEELinkAdvertisement"
}

Write-Console "=== Critical Settings (Should All Be Disabled) ===" -ForegroundColor Cyan

$allDisabled = $true
foreach ($setting in $settings.GetEnumerator()) {
    $prop = Get-NetAdapterAdvancedProperty -Name "Ethernet" -RegistryKeyword $setting.Value -ErrorAction SilentlyContinue

    if ($prop) {
        $displayValue = $prop.RegistryValue
        $status = if ($displayValue -eq 0 -or $displayValue -eq "Disabled") {
            "✓ DISABLED"
        } else {
            "✗ ENABLED (SHOULD BE DISABLED!)"
            $allDisabled = $false
        }

        $color = if ($displayValue -eq 0 -or $displayValue -eq "Disabled") { "Green" } else { "Red" }
        Write-Console "$($setting.Key): " -NoNewline
        Write-Console "$status" -ForegroundColor $color
    } else {
        Write-Console "$($setting.Key): NOT FOUND" -ForegroundColor Yellow
    }
}

Write-Console ""

if ($allDisabled) {
    Write-Console "✓ All settings correctly configured!" -ForegroundColor Green
    Write-Console "  RSC and EEE are disabled - this should prevent crashes." -ForegroundColor Gray
} else {
    Write-Console "✗ Some settings need attention!" -ForegroundColor Red
    Write-Console "  Please disable RSC in Device Manager → Advanced tab." -ForegroundColor Yellow
}

Write-Console "`n=== System Uptime ===" -ForegroundColor Cyan
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Console "Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Gray
Write-Console "Last Boot: $(Get-CimInstance Win32_OperatingSystem).LastBootUpTime)`n" -ForegroundColor Gray

# Show all adapter advanced properties (for reference)
Write-Console "=== All Advanced Properties (For Reference) ===" -ForegroundColor Cyan
Get-NetAdapterAdvancedProperty -Name "Ethernet" |
    Select-Object DisplayName, DisplayValue |
    Format-Table -AutoSize

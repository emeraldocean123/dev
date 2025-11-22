# Configuration Validator
# ======================
# Validates homelab.settings.json against required schema
# Prevents runtime failures due to missing/malformed configuration
#
# Location: shell-management/utils/_validate-config.ps1
# Prefix: _ (hidden from homelab.ps1 menu - utility function)

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    function Write-Console { param($Message, $ForegroundColor) Write-Host $Message -ForegroundColor $ForegroundColor }
}

# Default config path
if (-not $ConfigPath) {
    $ConfigPath = Join-Path $PSScriptRoot "../../.config/homelab.settings.json"
}

function Test-HomelabConfig {
    param([string]$Path)

    Write-Console "`nValidating homelab configuration..." -ForegroundColor Cyan

    # Check file existence
    if (-not (Test-Path $Path)) {
        Write-Console "ERROR: Configuration file not found: $Path" -ForegroundColor Red
        Write-Console "       Expected location: .config/homelab.settings.json" -ForegroundColor Yellow
        return $false
    }

    # Validate JSON syntax
    try {
        $config = Get-Content $Path -Raw | ConvertFrom-Json
    }
    catch {
        Write-Console "ERROR: Invalid JSON syntax in config file" -ForegroundColor Red
        Write-Console "       $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }

    # Track validation status
    $isValid = $true
    $errors = @()
    $warnings = @()

    # Required top-level keys
    $requiredKeys = @('Owner', 'Network', 'Paths')
    foreach ($key in $requiredKeys) {
        if (-not $config.PSObject.Properties.Name.Contains($key)) {
            $errors += "Missing required top-level key: $key"
            $isValid = $false
        }
    }

    # Validate Network section
    if ($config.Network) {
        if (-not $config.Network.Subnet) {
            $errors += "Missing Network.Subnet"
            $isValid = $false
        }
        if (-not $config.Network.Gateway) {
            $errors += "Missing Network.Gateway"
            $isValid = $false
        }
        if (-not $config.Network.Hosts) {
            $errors += "Missing Network.Hosts"
            $isValid = $false
        }
        else {
            # Validate Proxmox host entries have MAC addresses (for WoL)
            if ($config.Network.Hosts.Primary) {
                if (-not $config.Network.Hosts.Primary.Mac) {
                    $warnings += "Network.Hosts.Primary.Mac missing (Wake-on-LAN unavailable)"
                }
                if (-not $config.Network.Hosts.Primary.IP) {
                    $errors += "Network.Hosts.Primary.IP missing"
                    $isValid = $false
                }
            }
            if ($config.Network.Hosts.Secondary) {
                if (-not $config.Network.Hosts.Secondary.Mac) {
                    $warnings += "Network.Hosts.Secondary.Mac missing (Wake-on-LAN unavailable)"
                }
            }
        }
    }

    # Validate Paths section
    if ($config.Paths) {
        if (-not $config.Paths.DevRoot) {
            $errors += "Missing Paths.DevRoot"
            $isValid = $false
        }
    }

    # Validate Secrets section (optional but recommended)
    if (-not $config.Secrets) {
        $warnings += "Secrets section not defined (API keys should be externalized)"
    }
    else {
        # Check for common secret placeholders
        if ($config.Secrets.ImmichApiKey -eq "YOUR_API_KEY_HERE" -or
            $config.Secrets.ImmichApiKey -eq "" -or
            $null -eq $config.Secrets.ImmichApiKey) {
            $warnings += "Secrets.ImmichApiKey appears to be a placeholder"
        }
    }

    # Display results
    if ($Verbose -or $errors.Count -gt 0 -or $warnings.Count -gt 0) {
        Write-Console "`n========================================" -ForegroundColor Cyan
        Write-Console "  Configuration Validation Results" -ForegroundColor Cyan
        Write-Console "========================================" -ForegroundColor Cyan
        Write-Console ""
        Write-Console "Config File: $Path" -ForegroundColor Gray
        Write-Console ""
    }

    if ($errors.Count -gt 0) {
        Write-Console "ERRORS ($($errors.Count)):" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Console "  - $error" -ForegroundColor Red
        }
        Write-Console ""
    }

    if ($warnings.Count -gt 0) {
        Write-Console "WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Console "  - $warning" -ForegroundColor Yellow
        }
        Write-Console ""
    }

    if ($isValid -and $errors.Count -eq 0) {
        Write-Console "Status: VALID" -ForegroundColor Green
        if ($warnings.Count -eq 0) {
            Write-Console "        No issues found." -ForegroundColor Green
        }
        Write-Console ""
        return $true
    }
    else {
        Write-Console "Status: INVALID" -ForegroundColor Red
        Write-Console "        Fix errors before running infrastructure scripts." -ForegroundColor Yellow
        Write-Console ""
        return $false
    }
}

# Execute validation
$result = Test-HomelabConfig -Path $ConfigPath

# Exit with status code
if ($result) {
    exit 0
} else {
    exit 1
}

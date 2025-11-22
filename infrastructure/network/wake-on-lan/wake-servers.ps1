#
# Wake-on-LAN Script for Network Infrastructure
# Sends WOL magic packets to wake network devices from sleep/shutdown
# Supports individual devices or groups (proxmox, all)
#
# DEPLOYMENT:
#   Device: Portable - can run from any system on the network
#   Primary: Windows 11 development laptop (PowerShell)
#   Path:   ~/Documents/dev/wake-on-lan/wake-servers.ps1
#   Backup: Same location (this is the primary copy)
#
# TARGET DEVICES:
#   - intel-1250p-proxmox-host (192.168.1.40) - MAC: a8:b4:e0:07:9b:cd
#   - intel-n6005-proxmox-host (192.168.1.41) - MAC: 7c:2b:e1:13:92:4b
#   - synology-1520-nas (192.168.1.10) - MAC: 00:11:32:ff:4a:a5
#
# EXECUTION:
#   - Run from any system on 192.168.1.0/24 network
#   - Uses built-in .NET UDP sockets (no external dependencies)
#   - Sends UDP broadcast packets on port 9
#
# USAGE:
#   ./wake-servers.ps1 [1250p|n6005|synology|proxmox|all]
#   Examples:
#     ./wake-servers.ps1          # Wake all devices (default)
#     ./wake-servers.ps1 1250p    # Wake intel-1250p only
#     ./wake-servers.ps1 proxmox  # Wake both Proxmox servers

param(
    [Parameter(Position=0)]
    [ValidateSet('1250p', 'n6005', 'synology', 'proxmox', 'all', $null)]
    [string]$Target = 'all'
)

# Import shared utilities
$libPath = Join-Path $PSScriptRoot "../../lib/utils.ps1"
if (Test-Path $libPath) {
    . $libPath
} else {
    Write-Console "WARNING: Could not find shared library at $libPath" -ForegroundColor Yellow
    # Fallback: simple Write-Console function
    function Write-Console { param($Message, $ForegroundColor) Write-Console $Message -ForegroundColor $ForegroundColor }
}
# MAC addresses
$MAC_1250P = 'a8:b4:e0:07:9b:cd'
$MAC_N6005 = '7c:2b:e1:13:92:4b'
$MAC_SYNOLOGY = '00:11:32:ff:4a:a5'

# Function to send WOL magic packet
function Send-WOLPacket {
    param(
        [string]$MacAddress,
        [string]$ServerName
    )

    Write-Console "`nSending WOL magic packet to $ServerName ($MacAddress)..." -ForegroundColor Cyan

    try {
        # Remove colons/dashes from MAC address
        $mac = $MacAddress -replace '[:-]', ''

        # Convert MAC address to byte array
        $macBytes = [byte[]]@()
        for ($i = 0; $i -lt 12; $i += 2) {
            $macBytes += [Convert]::ToByte($mac.Substring($i, 2), 16)
        }

        # Create magic packet (6 bytes of 0xFF + MAC address repeated 16 times)
        $packet = [byte[]](,0xFF * 6) + ($macBytes * 16)

        # Send UDP broadcast packet
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.Connect([System.Net.IPAddress]::Broadcast, 9)
        [void]$udpClient.Send($packet, $packet.Length)
        $udpClient.Close()

        Write-Console "  Magic packet sent to $ServerName" -ForegroundColor Green
    }
    catch {
        Write-Console "  Error sending magic packet: $_" -ForegroundColor Red
    }
}

# Display header
Write-Console ""
Write-Console "========================================" -ForegroundColor Yellow
Write-Console "  Wake-on-LAN: Network Infrastructure" -ForegroundColor Yellow
Write-Console "========================================" -ForegroundColor Yellow
Write-Console ""

# Wake servers based on target
switch ($Target) {
    '1250p' {
        Send-WOLPacket -MacAddress $MAC_1250P -ServerName 'intel-1250p (192.168.1.40)'
    }
    'n6005' {
        Send-WOLPacket -MacAddress $MAC_N6005 -ServerName 'intel-n6005 (192.168.1.41)'
    }
    'synology' {
        Send-WOLPacket -MacAddress $MAC_SYNOLOGY -ServerName 'synology-1520-nas (192.168.1.10)'
    }
    'proxmox' {
        Send-WOLPacket -MacAddress $MAC_1250P -ServerName 'intel-1250p (192.168.1.40)'
        Start-Sleep -Milliseconds 500
        Send-WOLPacket -MacAddress $MAC_N6005 -ServerName 'intel-n6005 (192.168.1.41)'
    }
    'all' {
        Send-WOLPacket -MacAddress $MAC_1250P -ServerName 'intel-1250p (192.168.1.40)'
        Start-Sleep -Milliseconds 500
        Send-WOLPacket -MacAddress $MAC_N6005 -ServerName 'intel-n6005 (192.168.1.41)'
        Start-Sleep -Milliseconds 500
        Send-WOLPacket -MacAddress $MAC_SYNOLOGY -ServerName 'synology-1520-nas (192.168.1.10)'
    }
}

Write-Console ""
Write-Console "Done! Devices should be booting..." -ForegroundColor Green
Write-Console ""
Write-Console "Usage tips:" -ForegroundColor Gray
Write-Console "  ssh intel-1250p  # Connect to primary Proxmox host" -ForegroundColor Gray
Write-Console "  ssh intel-n6005  # Connect to backup server" -ForegroundColor Gray
Write-Console "  ssh synology     # Connect to Synology NAS" -ForegroundColor Gray
Write-Console ""

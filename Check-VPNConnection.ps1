#Requires -Version 5.1
<#
.SYNOPSIS
    Checks if connected to ExpressVPN, Cisco Secure Client, or WireGuard and warns if not.
.DESCRIPTION
    This script checks for active VPN connections by examining network adapters and routing.
    If no VPN connection is detected, it displays a balloon notification warning.
#>

# Configuration
$EnableLogging = $true
$LogPath = "$env:USERPROFILE\VPNCheck.log"

function Write-Log {
    param([string]$Message)
    if ($EnableLogging) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $LogPath -Append
    }
}

function Test-ExpressVPN {
    # Check for ExpressVPN process
    $process = Get-Process -Name "ExpressVPN*", "expressvpn*" -ErrorAction SilentlyContinue
    if ($process) {
        Write-Log "ExpressVPN process found: $($process.Name -join ' ')"
    }
    
    # Check for ExpressVPN named adapter
    $adapter = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
        $_.InterfaceDescription -like "*ExpressVPN*" -or 
        $_.Name -like "*ExpressVPN*"
    } | Where-Object { $_.Status -eq "Up" }
    
    if ($adapter) {
        Write-Log "ExpressVPN adapter found and up: $($adapter.Name)"
        return $true
    }
    
    # Check for ExpressVPN Lightway/TAP/Wintun adapter - ONLY if it has active VPN routes
    if ($process) {
        $vpnAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
            ($_.InterfaceDescription -like "*Lightway*" -or 
             $_.InterfaceDescription -like "*TAP-Windows*" -or
             $_.InterfaceDescription -like "*Wintun*") -and
            $_.Status -eq "Up"
        }
        
        foreach ($vpnAdapter in $vpnAdapters) {
            # Check if this adapter has VPN routes (0.0.0.0/1 and 128.0.0.0/1 are typical VPN split routes)
            $routes = Get-NetRoute -InterfaceIndex $vpnAdapter.ifIndex -ErrorAction SilentlyContinue
            $hasVpnRoute = $routes | Where-Object { 
                $_.DestinationPrefix -eq "0.0.0.0/0" -or 
                $_.DestinationPrefix -eq "0.0.0.0/1" -or
                $_.DestinationPrefix -eq "128.0.0.0/1"
            }
            
            if ($hasVpnRoute) {
                Write-Log "ExpressVPN tunnel active via $($vpnAdapter.Name) with VPN routes"
                return $true
            }
        }
        Write-Log "ExpressVPN process running but no active tunnel routes found"
    }
    
    return $false
}

function Test-CiscoSecureClient {
    # Check for Cisco VPN adapter
    $adapter = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
        $_.InterfaceDescription -like "*Cisco AnyConnect*" -or
        $_.InterfaceDescription -like "*Cisco Secure Client*" -or
        $_.Name -like "*Cisco*"
    } | Where-Object { $_.Status -eq "Up" }
    
    if ($adapter) {
        Write-Log "Cisco Secure Client adapter found and up: $($adapter.Name)"
        return $true
    }
    
    return $false
}

function Test-WireGuard {
    # Check for WireGuard network adapter
    $adapter = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object {
        $_.InterfaceDescription -like "*WireGuard*" -or
        $_.Name -like "*WireGuard*" -or
        $_.Name -like "wg*"
    } | Where-Object { $_.Status -eq "Up" }
    
    if ($adapter) {
        Write-Log "WireGuard adapter found and up: $($adapter.Name)"
        return $true
    }
    
    # Check WireGuard tunnel service
    $service = Get-Service -Name "WireGuardTunnel*" -ErrorAction SilentlyContinue | 
               Where-Object { $_.Status -eq "Running" }
    if ($service) {
        Write-Log "WireGuard tunnel service running: $($service.Name)"
        return $true
    }
    
    return $false
}

function Show-VPNWarning {
    Add-Type -AssemblyName System.Windows.Forms
    
    Write-Log "Showing warning popup"
    
    [System.Windows.Forms.MessageBox]::Show(
        "You are not connected to any VPN (ExpressVPN, Cisco Secure Client, or WireGuard).`n`nYour connection may not be secure!",
        "VPN Warning",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
    
    Write-Log "Popup closed by user"
}

# Main execution

# Single instance check - prevent multiple popups
$mutexName = "Global\VPNCheckScript"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)
if (-not $mutex.WaitOne(0)) {
    # Another instance is already running
    exit
}

try {
    Write-Log "=== VPN Check Started ==="

$expressVPN = Test-ExpressVPN
$ciscoVPN = Test-CiscoSecureClient
$wireGuard = Test-WireGuard

Write-Log "ExpressVPN: $expressVPN, Cisco: $ciscoVPN, WireGuard: $wireGuard"

if (-not ($expressVPN -or $ciscoVPN -or $wireGuard)) {
    Write-Log "No VPN detected - showing warning"
    Show-VPNWarning
}
else {
    $connectedVPN = @()
    if ($expressVPN) { $connectedVPN += "ExpressVPN" }
    if ($ciscoVPN) { $connectedVPN += "Cisco Secure Client" }
    if ($wireGuard) { $connectedVPN += "WireGuard" }
    Write-Log "VPN connected: $($connectedVPN -join ', ')"
}

Write-Log "=== VPN Check Completed ==="
}
finally {
    # Release mutex
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}

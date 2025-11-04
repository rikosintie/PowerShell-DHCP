<#
.SYNOPSIS
Scans subnets and compares active IPs against DHCP server to identify static assignments
.DESCRIPTION
Uses nmap to discover active hosts and compares them against DHCP leases/reservations
to identify devices using static IP addresses
.PARAMETER DHCPServer
DHCP server hostname or IP address
.PARAMETER Subnets
Array of subnets to scan in CIDR notation (e.g., “192.168.1.0/24”)
.PARAMETER NmapPath
Path to nmap executable (default: “nmap” assumes it’s in PATH)
.EXAMPLE
.\Scan-StaticIPs.ps1 -DHCPServer “dhcp01” -Subnets @(“192.168.1.0/24”, “10.0.10.0/24”)
#>

param(
[Parameter(Mandatory=$true)]
[string]$DHCPServer,

[Parameter(Mandatory=$true)]
[string[]]$Subnets,

[string]$NmapPath = "nmap",

    [string]$OutputPath = ".\dhcp-static-report.csv"
)

# Check if nmap is available

try {
$null = & $NmapPath –version 2>&1
} catch {
Write-Error “Nmap not found. Please install nmap or specify path with -NmapPath”
exit 1
}

# Check if DHCP cmdlets are available

if (-not (Get-Command Get-DhcpServerv4Lease -ErrorAction SilentlyContinue)) {
Write-Error “DHCP PowerShell module not found. Install RSAT tools or run on DHCP server.”
exit 1
}

Write-Host “=== DHCP vs Static IP Scanner ===” -ForegroundColor Cyan
Write-Host “”

# Step 1: Gather DHCP data

Write-Host “[1/3] Collecting DHCP data from $DHCPServer…” -ForegroundColor Yellow

$dhcpIPs = @{}
$allScopes = Get-DhcpServerv4Scope -ComputerName $DHCPServer

foreach ($scope in $allScopes) {
Write-Host “  - Processing scope: $($scope.ScopeId)” -ForegroundColor Gray

#```
# Get leases
try {
    $leases = Get-DhcpServerv4Lease -ComputerName $DHCPServer -ScopeId $scope.ScopeId
    foreach ($lease in $leases) {
        $dhcpIPs[$lease.IPAddress.ToString()] = [PSCustomObject]@{
            Type = "DHCP Lease"
            Hostname = $lease.HostName
            MAC = $lease.ClientId
            Scope = $scope.ScopeId.ToString()
        }
    }
} catch {
    Write-Warning "  Could not retrieve leases for scope $($scope.ScopeId)"
}

# Get reservations
try {
    $reservations = Get-DhcpServerv4Reservation -ComputerName $DHCPServer -ScopeId $scope.ScopeId
    foreach ($res in $reservations) {
        $dhcpIPs[$res.IPAddress.ToString()] = [PSCustomObject]@{
            Type = "DHCP Reservation"
            Hostname = $res.Name
            MAC = $res.ClientId
            Scope = $scope.ScopeId.ToString()
        }
    }
} catch {
    Write-Warning "  Could not retrieve reservations for scope $($scope.ScopeId)"
}
#```

}

Write-Host “  Found $($dhcpIPs.Count) DHCP-managed IPs” -ForegroundColor Green
Write-Host “”

# Step 2: Scan networks with nmap

Write-Host “[2/3] Scanning networks with nmap…” -ForegroundColor Yellow

$allActiveIPs = @()

foreach ($subnet in $Subnets) {
Write-Host “  - Scanning $subnet…” -ForegroundColor Gray

#```
# Run nmap with grepable output
$nmapOutput = & $NmapPath -sn $subnet -oG - --exclude $DHCPServer 2>$null

# Parse output for active hosts
$activeIPs = $nmapOutput | Select-String "Status: Up" | ForEach-Object {
    if ($_ -match "Host: (\d+\.\d+\.\d+\.\d+)") {
        $matches[1]
    }
}

if ($activeIPs) {
    $allActiveIPs += $activeIPs
    Write-Host "    Found $($activeIPs.Count) active hosts" -ForegroundColor Gray
}
#```

}

Write-Host “  Total active hosts: $($allActiveIPs.Count)” -ForegroundColor Green
Write-Host “”

# Step 3: Compare and generate report

Write-Host “[3/3] Comparing results…” -ForegroundColor Yellow

$results = @()

foreach ($ip in $allActiveIPs) {
# Try to resolve hostname
$hostname = try {
[System.Net.Dns]::GetHostEntry($ip).HostName
} catch {
“N/A”
}

#```
if ($dhcpIPs.ContainsKey($ip)) {
    $dhcpInfo = $dhcpIPs[$ip]
    $results += [PSCustomObject]@{
        IPAddress = $ip
        ResolvedHostname = $hostname
        AssignmentType = $dhcpInfo.Type
        DHCPHostname = $dhcpInfo.Hostname
        MACAddress = $dhcpInfo.MAC
        Scope = $dhcpInfo.Scope
        Status = "DHCP Managed"
    }
} else {
    $results += [PSCustomObject]@{
        IPAddress = $ip
        ResolvedHostname = $hostname
        AssignmentType = "Static IP"
        DHCPHostname = "N/A"
        MACAddress = "N/A"
        Scope = "N/A"
        Status = "⚠️ NOT IN DHCP"
    }
}
#```

}

# Display summary

Write-Host “”
Write-Host “=== Summary ===” -ForegroundColor Cyan
$staticCount = ($results | Where-Object { $_.AssignmentType -eq “Static IP” }).Count
$leaseCount = ($results | Where-Object { $_.AssignmentType -eq “DHCP Lease” }).Count
$reservationCount = ($results | Where-Object { $_.AssignmentType -eq “DHCP Reservation” }).Count

Write-Host “Static IPs:         $staticCount” -ForegroundColor Red
Write-Host “DHCP Leases:        $leaseCount” -ForegroundColor Green
Write-Host “DHCP Reservations:  $reservationCount” -ForegroundColor Green
Write-Host “”

# Display static IPs

if ($staticCount -gt 0) {
Write-Host “=== Static IP Addresses ===” -ForegroundColor Red
$results | Where-Object { $_.AssignmentType -eq “Static IP” } |
Format-Table IPAddress, ResolvedHostname -AutoSize
}

# Export results

$results | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host “Full report exported to: $OutputPath” -ForegroundColor Green
Write-Host “”

# Return results object

return $results

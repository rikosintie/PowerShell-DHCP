# https://4sysops.com/archives/analyze-dhcp-server-with-powershell/
# 
<#
Simple script to print DHCP server and Scope Statistics
#>
$DHCPServer = "192.168.10.221"
$Exportpath = "DHCPLeases.csv"
$ExportpathRes = "DHCPRes.csv"
$ExportpathScope = "DHCPScope.csv"
$Scope = "192.168.10.0"

$dhcps = (Get-DhcpServerInDC).DnsName
$dhcps | foreach-Object {Get-DhcpServerv4Scope -ComputerName $_} |
    Select-Object -Property ScopeId, SubnetMask, Name, State  |
    Export-Csv -Path $ExportpathScope -NoTypeInformation |
    Write-Host
Write-Host
Write-Host '--------- Server Log Settings--------'
Get-DhcpServerAuditLog -ComputerName $dhcps
Write-Host
Write-Host '--------- Server Settings-----------'
Get-DhcpServerSetting -ComputerName $dhcps

Write-Host 
Write-Host '--------- Server Statistics-----------'
Get-DhcpServerv4Statistics -ComputerName $dhcps

Write-Host
Write-Host '--------- Scope Statistics-----------'
Get-DhcpServerv4ScopeStatistics -ComputerName $dhcps
Write-Host '-------------------------------------'
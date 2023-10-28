# https://4sysops.com/archives/analyze-dhcp-server-with-powershell/
# 
# $DHCPServer = "192.168.10.221"
# $Exportpath = "DHCPLeases.csv"
#$ExportpathRes = "DHCPRes.csv"
# $Scope = "192.168.10.0"
$ExportpathScope = "DHCPScope.csv"


$dhcps = (Get-DhcpServerInDC).DnsName
$dhcps | foreach-Object {Get-DhcpServerv4Scope -ComputerName $_} |
    Select-Object -Property ScopeId, SubnetMask, Name, State  |
    Export-Csv -Path $ExportpathScope -NoTypeInformation |
    Write-Host

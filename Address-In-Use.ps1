# https://4sysops.com/archives/analyze-dhcp-server-with-powershell/

$Exportpath = "Addresses-in-use.csv"

$dhcps = (Get-DhcpServerInDC).DnsName
$dhcps | foreach-Object {Get-DhcpServerv4Lease -ComputerName $_} |
    Select-Object -Property IPAddress, ScopeId,  ClientId, HostName, AddressState, LeaseExpiryTime   |
    Export-Csv -Path $Exportpath -NoTypeInformation |
    Write-Host
Write-Host 
Write-Host '-------Addresses in the Deny List -------'
Get-DhcpServerv4Filter -ComputerName $dhcps
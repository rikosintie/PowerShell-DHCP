# https://4sysops.com/archives/analyze-dhcp-server-with-powershell/
# 
$DHCPServer = "192.168.10.221"
$Exportpath = "C:\Users\mhubbard\Documents\DHCPLeases.csv"
$ExportpathRes = "DHCPRes.csv"
$Scope = "10.76.20.0"

 Get-DhcpServerv4Lease -computerName $DHCPServer -ScopeId $Scope |
    Select-Object -Property IPAddress, ClientId, AddressState  |
    Export-Csv -Path $Exportpath -NoTypeInformation

 Get-DhcpServerv4Reservation -ComputerName $DHCPServer $Scope |
     Export-Csv -Path $ExportpathRes -NoTypeInformation

$Le = Import-Csv $Exportpath

$Leases = foreach ($item in $Le) {
    New-Object -TypeName PSObject -Property @{
    ip=$($item."IPAddress")
    mac=$($item.ClientId)
    } | Select-Object ip, mac
   }

# Write-Host $leases
$Leases | Export-Csv -Path "lease.csv" -NoTypeInformation
$a = Import-Csv "lease.csv"
$Leases = foreach ($item in $a) {
    $ip = $($item.ip)
    $mac = $($item.mac)
    $mac=$mac-replace'[-]', ':'
    Write-Host $ip","$mac
    $leases | out-file -FilePath "leases1.csv"
    }

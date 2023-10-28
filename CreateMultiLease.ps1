# https://4sysops.com/archives/analyze-dhcp-server-with-powershell/
# 
<# filename is the DHCPScope.csv file created by DHCPScope.ps1
The script reads each scope and pulls down the reservations. 
The output is saved to Multilease.csv
To execute:
PS C:\Users\mhubbard\Documents> .\CreateMultiLease.ps1 .\DHCPScope.csv
#> 

param ([string]$filename = "filename")
$ExportFile = "MultiLease.csv"
$a = Import-Csv $filename
# delete Multilease.csv if it exists
Remove-Item MultiLease.*
foreach ($item in $a) {
    $Scope=$($item."ScopeId")

    Get-DhcpServerv4Lease -computerName $DHCPServer -ScopeId $Scope |
    Select-Object -Property IPAddress, ClientId, AddressState, Description  |
    Export-Csv -Path $ExportFile -NoTypeInformation -Append
}
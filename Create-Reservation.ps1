<# https://lazyadmin.nl/powershell/import-csv-powershell/
Reads DHCPRes.csv and creates new reservations. 

To move reservations to a new scope:
Create DHCPRes.csv using export-lease.ps1. 
Open in excel and change the existing subnet to the new subnet.
Run Create-Reservations.ps1 to add the reservations to the new dhcp scope.
To display the CSV on screen
Import-Csv .\DHCPRes.csv | ft
#>

function bulkDHCPReservations{
 
 Param(
     [parameter(Mandatory=$true)]
     $DHCPSrv
 )
 
   Import-Csv .\DHCPRes.csv | foreach{
     $_ | Add-DhcpServerv4Reservation -IpAddress $_.IPAddress -ComputerName $DHCPSrv
 
     # Set-DhcpServerv4OptionValue -optionID 66 -value $_.Option66 `
     #   -ReservedIP $FreeIP -ComputerName $DHCPSrv
     # Set-DhcpServerv4OptionValue -optionID 67 -value $_.Option67 `
     #   -ReservedIP $FreeIP -ComputerName $DHCPSrv
     }
     
 }

 bulkDHCPReservations('192.168.10.221')

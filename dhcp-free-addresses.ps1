# https://4sysops.com/archives/analyze-dhcp-server-with-powershell/
# 
# Export-DhcpServer -ComputerName "192.168.10.221" -File "./dhcpexport.xml" -ScopeId 192.168.10.0,10.112.100.0 -Leases
# finds free addresses in a scope. Change 21 to find a different number of free addresses.
DhcpServerv4FreeIPAddress -ComputerName 192.168.10.221 -ScopeId 192.168.10.0 `
-StartAddress 192.168.10.100 -NumAddress 21

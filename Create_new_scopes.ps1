# Import the CSV file. It must be in the same directory as the script
$scopes = Import-Csv -Path "home-DHCP-Data.csv"
<#
To add multiple dns server serparate the ip address or hostnames with a hypen
Example
10.100.100.23-10.100.100.23

To set lease time use this format
Days hours minutes seconds
00.00:00:00
Example of an 8 hour lease time
00.08:00:00
#>

# Loop through each scope in the CSV
foreach ($scope in $scopes) {
     try {
        # Create the DHCP Scope
        Add-DhcpServerv4Scope -Name $scope.'Scope_Name' `
            -Description $scope.'Scope_Desc' `
            -StartRange $scope.Range_Start `
            -EndRange $scope.Range_End `
            -SubnetMask $scope.Mask `
            -State Active `
            -ComputerName $scope.'Server'
            # -ServerIPAddress $scope.'Server'


        # Add Exclusion Range if defined
        if ($scope.Exclude_Start -and $Scope.Exclude_end) {
            Add-DhcpServerv4ExclusionRange -ScopeId $scope.'scope' `
                -StartRange $scope.exclude_start `
                -EndRange $scope.exclude_end
        }

        # Add Router Option (Default Gateway)
        if ($scope.router) {
            Set-DhcpServerv4OptionValue -ScopeId $scope.'Scope' `
                -OptionId 3 `
                -Value $scope.Router
        }

        # Set DNS Server Option
        if ($scope.'dns_server') {
            $dnsServers = $scope.'dns_server' -split "-"

            # Remove any existing DNS server option for the scope
            Remove-DhcpServerv4OptionValue -ScopeId $scope.'Scope' -OptionId 6 -ErrorAction SilentlyContinue

            Set-DhcpServerv4OptionValue -ScopeId $scope.'Scope' `
                                    -OptionId 6 `
                                    -Value $dnsServers
        }

        # Set Domain Name Option
        if ($scope.'domain_name') {
            Set-DhcpServerv4OptionValue -ScopeId $scope.'Scope' `
                -OptionId 15 `
                -Value $scope.'domain_name'
        }

        # Set Lease Duration if defined
        if ($scope.lease) {
            Set-DhcpServerv4Scope -ScopeId $scope.'Scope' `
                -LeaseDuration ([TimeSpan]::Parse($scope.lease))
        }
        # If everything is successful
        Write-Host "DHCP scope" $Scope.Scope_Name $Scope.Scope "created successfully."

    }
    catch {
        # Catch any errors and display an error message
        Write-Host "An error occurred on scope $($scope.'Scope_Name'): $_" -ForegroundColor Red
    }
}

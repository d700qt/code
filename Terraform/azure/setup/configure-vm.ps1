$creds = get-credential
$vm = read-host -Prompt "Please enter hostname or IP address"

set-item wsman:\localhost\Client\TrustedHosts -value 1.2.3.4
get-item wsman:\localhost\Client\TrustedHosts
$pssession = New-PSSession -ComputerName $vm -Credential $creds

# choco installs
<#
    choco install git
    choco install visualstudiocode
    choco install 7zip
    choco install azure-cli
    Copy-Item -path "..\..\Bamboo\${var.bamboo_installer_filename}" -Destination "C:\bootstrap" -ToSession $pssession -Verbose
#>




<#
Manual steps
Apply trial Bamboo license
Bamboo config

Installed VS 2017 Community edition, specifically:
- Testing tools core features
- MS build (+ some automatically selected dependencies
- Plus the core VS IDE editor
- .NET 4.6.1 Targeting pack (to get the HelloWorld VS project working - the VS project targets 4.6.1)
#>

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




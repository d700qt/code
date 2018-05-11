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



# Bamboo setup
Invoke-Command -Session $psSession -ScriptBlock {
    start-process -filepath "C:\bootstrap\${var.bamboo_installer_filename}" -ArgumentList "-q -wait" -WorkingDirectory "C:\bootstrap" -Wait -Verbose
    start-process -filepath "$env:ProgramFiles\Bamboo\InstallAsService.bat" - -WorkingDirectory "$env:ProgramFiles\Bamboo" -wait -verbose
    start-service bamboo
}

Enter-PSSession -Session $pssession

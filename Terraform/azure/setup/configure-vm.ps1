$creds = get-credential
$vm = read-host -Prompt "Please enter IP address"

#set-item wsman:\localhost\Client\TrustedHosts -value $vm

$psSession = New-PSSession -ComputerName $vm -Credential $creds
Invoke-Command -Session $psSession -ScriptBlock {
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
Invoke-Command -Session $psSession -ScriptBlock {
    choco feature enable -n allowGlobalConfirmation
    choco install git
    choco install visualstudiocode
}
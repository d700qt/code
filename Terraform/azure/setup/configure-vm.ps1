$creds = get-credential
$vm = read-host -Prompt "Please enter hostname or IP address"

set-item wsman:\localhost\Client\TrustedHosts -value 1.2.3.4
get-item wsman:\localhost\Client\TrustedHosts
$pssession = New-PSSession -ComputerName $vm -Credential $creds

icm -Session $pssession -ScriptBlock{
    new-item -path "c:\bootstrap" -type Directory
} 

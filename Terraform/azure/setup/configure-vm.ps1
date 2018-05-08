$creds = get-credential
$vm = read-host -Prompt "Please enter IP address"

#set-item wsman:\localhost\Client\TrustedHosts -value $vm

New-PSSession -ComputerName $vm -Credential $creds
Invoke-Command -Session $psSession -ScriptBlock {hostname}
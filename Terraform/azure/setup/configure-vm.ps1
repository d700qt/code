$creds = get-credential
$vm = read-host -Prompt "Please enter IP address"

set-item wsman:\localhost\Client\TrustedHosts -value 1.2.3.4
get-item wsman:\localhost\Client\TrustedHosts
$pssession = New-PSSession -ComputerName $vm -Credential $creds

new-item -path "c:\bootstrap" -type Directory
Copy-Item "C:\code\Bamboo\atlassian-bamboo-6.5.0.zip" -Destination "C:\bootstrap" -ToSession $pssession

new-psdrive -Name "H" -PSProvider "FileSystem" -Root "\\$vm\c$" -Credential $creds
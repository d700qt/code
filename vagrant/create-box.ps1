vagrant /?

# create box from virtual box VM
vagrant package --base windows-server-2016 --output c:\hashicorp\vagrant\boxes\windows-server-2016.box # --vagrantfile C:\code\vagrant\boxes\windows-server-2016\vagrantfile

# add box to vagrant
vagrant box add c:\hashicorp\vagrant\boxes\windows-server-2016.box --name windows-server-2016


set-item wsman:\localhost\Client\TrustedHosts -value *
get-item wsman:\localhost\Client\TrustedHosts

$cred = Get-Credential
$pssession = New-PSSession -ComputerName 127.0.0.1 -Port 55985 -Credential $cred 

icm -Session $pssession -ScriptBlock {hostname}
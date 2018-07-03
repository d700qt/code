copy-item -Path "C:\code\vagrant\windows-server-2016\modules\xSQLServer" -ToSession $db -Destination "C:\Program Files\WindowsPowerShell\Modules" -Recurse -Force

configuration sqlserver {
    
    Param ()

    Import-DscResource -ModuleName SQLServerDSC -ModuleVersion 11.3.0.01

    $majorSQLVersion = 2016
    $sqlProductNumber = 120
    $sqlInstanceName = "MSSQLSERVER"

    $vagrantPassword =  ConvertTo-SecureString "vagrant" -AsPlainText -Force
    $saCredential = New-Object System.Management.Automation.PSCredential("sa", $vagrantPassword)
    $windowsCredential = New-Object System.Management.Automation.PSCredential("vagrant", $vagrantPassword)

    WindowsFeature NETFrameworkCore {
        Ensure = "true"
        Name = "NET-Framework-Core"
    }

    Script MSDTCInstall {
        DependsOn = "[WindowsFeature]NETFrameworkCore"
        GetScript = {
            $resultString = [string](Get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC")
            $resultString += [string](Get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security")
            $resultString += ";MSDTC service status:" + (get-service -name msdtc).status
            return @{Result = $resultString}
        }
        SetScript = {
            Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccess" -value 1                #Network DTC Access
            Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccessTransactions" -value 1    #Allow inbound
            Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccessInbound" -value 1         #Allow inbound
            Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccessOutbound" -value 1        #Allow Outbound
            Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccessAdmin" -value 0           #Don't allow Remote Administration
            Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "NetworkDtcAccessClients" -value 0         #Don't allow Remote Clients
            Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security" -name "XaTransactions" -value 0                  #Disable XA Transactions
            Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC" -name "AllowOnlySecureRpcCalls" -value 1                  #Mutual Authentication Required
            Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC" -name "FallbackToUnsecureRPCIfNecessary" -value 0         #No Authentication Required
            Set-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC" -name "TurnOffRpcSecurity" -value 0                       #No Authentication Required
            restart-service -Name MSDTC
        }
        TestScript = {
            if ( ((get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security").NetworkDtcAccess -eq "1") -and `
                ((get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security").NetworkDtcAccessTransactions -eq "1") -and `
                ((get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security").NetworkDtcAccessInbound -eq "1") -and `
                ((get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security").NetworkDtcAccessOutbound -eq "1") -and `
                ((get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security").NetworkDtcAccessAdmin -eq "0") -and `
                ((get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security").NetworkDtcAccessClients -eq "0") -and `
                ((get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC\Security").XaTransactions -eq "0") -and `
                ((get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC").AllowOnlySecureRpcCalls -eq "1") -and `
                ((get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC").FallbackToUnsecureRPCIfNecessary -eq "0") -and `
                ((get-ItemProperty -path "HKLM:\Software\Microsoft\MSDTC").TurnOffRpcSecurity -eq "0") )
            {
                return $true
            } else {
                return $false
            }
        }
    }

    xSqlServerSetup SQLInstanceInstall {
        DependsOn = "[Script]MSDTCInstall"
        SourcePath = "C:\Setup"
        SourceCredential = $windowsCredential
        SetupCredential = $windowsCredential
        InstanceName = $sqlInstanceName
        Features = "SQLENGINE,IS,REPLICATION"
        SQLSysAdminAccounts = "" # This always includes the Setup Account as well as any given here
        SecurityMode = "SQL"
        SAPwd = $saCredential
        SQLSvcAccount = $windowsCredential
        AgtSvcAccount = $windowsCredential
        SQLCollation = "SQL_Latin1_General_CP1_CI_AS"
        BrowserSvcStartupType = "Disabled"
        InstallSharedDir = "C:\Program Files\Microsoft SQL Server"
        InstallSharedWOWDir = "C:\Program Files (x86)\Microsoft SQL Server"
        InstanceDir = "C:\Program Files\Microsoft SQL Server"
        InstallSQLDataDir = "C:"
        SQLUserDBDir = "C:\MSSQL${sqlProductNumber}.${SQLInstanceName}\MSSQL\Data"
        SQLUserDBLogDir = "C:\MSSQL${sqlProductNumber}.${SQLInstanceName}\MSSQL\Data"
        SQLTempDBDir = "C:\MSSQL${sqlProductNumber}.${SQLInstanceName}\MSSQL\Data"
        SQLTempDBLogDir = "C:\MSSQL${sqlProductNumber}.${SQLInstanceName}\MSSQL\Data"
    }

    xSqlServerNetwork SQLInstanceTCPNetworkConfig {
        InstanceName = $SQLInstanceName # Default instance
        ProtocolName = "TCP"
        IsEnabled = $true
        TCPPort = "1433"
        DependsOn = "[xSQLServerSetup]SQLInstanceInstall"
    }


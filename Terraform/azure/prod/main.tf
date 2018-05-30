/*
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
*/

/*
Run terraform init -backend-config="backend.private" to switch backend
or terraform init -backend-config="bucket=<bucketname>" -backend-config "key=<keyname>"
*/
terraform {
  backend "s3" {}
}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

data "azurerm_resource_group" "rg_terraform" {
  name = "rg_terraform"
}

data "azurerm_network_security_group" "nsg_terraform" {
  name                = "nsg_terraform"
  resource_group_name = "${data.azurerm_resource_group.rg_terraform.name}"
}

data "azurerm_virtual_network" "vnet_terraform" {
  name                = "vnet_terraform"
  resource_group_name = "${data.azurerm_resource_group.rg_terraform.name}"
}

data "azurerm_subnet" "subnet_terraform" {
  name                 = "subnet_terraform"
  resource_group_name  = "${azurerm_resource_group.rg_terraform.name}"
  virtual_network_name = "${data.azurerm_virtual_network.vnet_terraform.name}"
  resource_group_name  = "${data.azurerm_resource_group.rg_terraform.name}"
}

data "azurerm_public_ip" "pip_win2" {
  name                = "pip_win2"
  resource_group_name = "${data.azurerm_resource_group.rg_terraform.name}"
}

resource "azurerm_network_interface" "vnic_win2" {
  name                      = "vnic_win2"
  location                  = "${data.azurerm_resource_group.rg_terraform.location}"
  resource_group_name       = "${data.azurerm_resource_group.rg_terraform.name}"
  network_security_group_id = "${data.azurerm_network_security_group.nsg_terraform.id}"

  ip_configuration {
    name                          = "ip_win2"
    subnet_id                     = "${data.azurerm_subnet.subnet_terraform.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${data.azurerm_public_ip.pip_win2.id}"
  }
}

resource "azurerm_virtual_machine" "win2" {
  name                  = "win2"
  location              = "${data.azurerm_resource_group.rg_terraform.location}"
  resource_group_name   = "${data.azurerm_resource_group.rg_terraform.name}"
  network_interface_ids = ["${azurerm_network_interface.vnic_win2.id}"]
  vm_size               = "Standard_B2ms"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServerSemiAnnual"
    sku       = "Datacenter-Core-1709-smalldisk"
    version   = "latest"                         #1709.0.20180412
  }

  storage_os_disk {
    name    = "win2_disk_os"
    caching = "ReadWrite"

    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "adeweetman-win2"
    admin_username = "${var.machine_username}"
    admin_password = "${var.machine_password}"
  }

  os_profile_windows_config {
    winrm = {
      protocol = "http"
    }
  }

  tags {
    environment = "prod"
  }
}

resource "null_resource" "bootstrap" {
  depends_on = ["azurerm_virtual_machine.win2"]

  provisioner "local-exec" {
    command = <<EOT
      $password = "${var.machine_password}" | ConvertTo-SecureString -asPlainText -Force;
      $username = "${var.machine_username}";
      $cred = New-Object System.Management.Automation.PSCredential($username,$password);  
      while ($true) {
        try {
          $pssession = New-PSSession -ComputerName "${data.azurerm_public_ip.pip_win2.ip_address}" -Credential $cred -ErrorAction Stop
        } catch {
          write-warning -message "WinRM connection could not be made..."
        }
        if ($pssession -eq $null) {
          Start-Sleep -Seconds 20
        } else {
            Write-Host "WinRM connection made";
            break;
        }
      }
      Invoke-Command -Session $psSession -ScriptBlock {
        Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -confirm:$false
      }
      
    EOT

    interpreter = ["PowerShell", "-Command"]
  }
}

output "win2_public_fqdn" {
  value = "${data.azurerm_public_ip.pip_win2.domain_name_label}.${data.azurerm_resource_group.rg_terraform.location}.cloudapp.azure.com"
}

output "win2_public_ip_address" {
  value = "${data.azurerm_public_ip.pip_win2.ip_address}"
}

/*
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
*/
provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "rg_terraform" {
  name     = "rg_terraform"
  location = "West Europe"
}

resource "azurerm_network_security_group" "nsg_terraform" {
  name                = "nsg_terraform"
  location            = "${azurerm_resource_group.rg_terraform.location}"
  resource_group_name = "${azurerm_resource_group.rg_terraform.name}"

  security_rule {
    name                       = "WinRM"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "RDP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "vnet_terraform" {
  name                = "vnet_terraform"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.rg_terraform.location}"
  resource_group_name = "${azurerm_resource_group.rg_terraform.name}"
}

resource "azurerm_subnet" "subnet_terraform" {
  name                 = "subnet_terraform"
  resource_group_name  = "${azurerm_resource_group.rg_terraform.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet_terraform.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "pip_terraform" {
  name                         = "pip_terraform"
  location                     = "${azurerm_resource_group.rg_terraform.location}"
  resource_group_name          = "${azurerm_resource_group.rg_terraform.name}"
  public_ip_address_allocation = "Static"
  idle_timeout_in_minutes      = 30

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "vnic_terraform" {
  name                      = "vnic_terraform"
  location                  = "${azurerm_resource_group.rg_terraform.location}"
  resource_group_name       = "${azurerm_resource_group.rg_terraform.name}"
  network_security_group_id = "${azurerm_network_security_group.nsg_terraform.id}"

  ip_configuration {
    name                          = "ip_terraform"
    subnet_id                     = "${azurerm_subnet.subnet_terraform.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.pip_terraform.id}"
  }
}

resource "azurerm_virtual_machine" "vm_terraform" {
  name                  = "vm_terraform"
  location              = "${azurerm_resource_group.rg_terraform.location}"
  resource_group_name   = "${azurerm_resource_group.rg_terraform.name}"
  network_interface_ids = ["${azurerm_network_interface.vnic_terraform.id}"]
  vm_size               = "Standard_B2ms"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"                 #1709.0.20180412
  }

  storage_os_disk {
    name              = "disk_os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "tf-01"
    admin_username = "${var.machine_username}"
    admin_password = "${var.machine_password}"
  }

  os_profile_windows_config {
    winrm = {
      protocol = "http"
    }
  }

  tags {
    environment = "dev"
  }

  provisioner "local-exec" {
    command = <<EOT
      $password = "${var.machine_password}" | ConvertTo-SecureString -asPlainText -Force;
      $username = "${var.machine_username}";
      $cred = New-Object System.Management.Automation.PSCredential($username,$password);  
      while ($true) {
        try {
          $pssession = New-PSSession -ComputerName "${azurerm_public_ip.pip_terraform.ip_address}" -Credential $cred -ErrorAction Stop
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
        Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
      }
      Invoke-Command -Session $psSession -ScriptBlock {
          choco feature enable -n allowGlobalConfirmation
          choco install git
          choco install visualstudiocode
          choco install 7zip
          choco install azure-cli
          choco install jdk8
      }
    EOT

    interpreter = ["PowerShell", "-Command"]
  }
}

output "public_ip_address" {
  value = "${azurerm_public_ip.pip_terraform.ip_address}"
}

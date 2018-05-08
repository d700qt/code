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
    offer     = "WindowsServerSemiAnnual"
    sku       = "Datacenter-Core-1709-smalldisk"
    version   = "latest"                         #1709.0.20180412
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

  provisioner "remote-exec" {
    connection {
      type     = "winrm"
      user     = "${var.machine_username}"
      password = "${var.machine_password}"
    }

    inline = [
      "hostname > c:\\windows\\temp\\hostname.txt",
    ]

    on_failure = "continue"
  }
}

output "public_ip_address" {
  value = "${azurerm_public_ip.pip_terraform.ip_address}"
}

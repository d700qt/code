/*
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
*/

# Run terraform init -backend-config="backend.private" to switch backend
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

data "azurerm_public_ip" "pip_lnx1" {
  name                = "pip_lnx1"
  resource_group_name = "${data.azurerm_resource_group.rg_terraform.name}"
}

resource "azurerm_network_interface" "vnic_lnx1" {
  name                      = "vnic_lnx1"
  location                  = "${data.azurerm_resource_group.rg_terraform.location}"
  resource_group_name       = "${data.azurerm_resource_group.rg_terraform.name}"
  network_security_group_id = "${data.azurerm_network_security_group.nsg_terraform.id}"

  ip_configuration {
    name                          = "ip_lnx1"
    subnet_id                     = "${data.azurerm_subnet.subnet_terraform.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${data.azurerm_public_ip.pip_lnx1.id}"
  }
}

resource "azurerm_virtual_machine" "lnx1" {
  name                  = "${var.lnx_machine_name_suffix}"
  location              = "${data.azurerm_resource_group.rg_terraform.location}"
  resource_group_name   = "${data.azurerm_resource_group.rg_terraform.name}"
  network_interface_ids = ["${azurerm_network_interface.vnic_lnx1.id}"]
  vm_size               = "Standard_B2ms"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"       #1709.0.20180412
  }

  storage_os_disk {
    name              = "disk_os_${var.lnx_machine_name_suffix}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.machine_name_prefix}-${var.lnx_machine_name_suffix}"
    admin_username = "${var.machine_username}"
    admin_password = "${var.machine_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "global"
  }
}

resource "null_resource" "bootstrap" {
  depends_on = ["azurerm_virtual_machine.lnx1"]

  provisioner "local-exec" {
    command = <<EOT
      echo "hello"
    EOT
  }
}

output "terraform_public_fqdn" {
  value = "${data.azurerm_public_ip.pip_lnx1.domain_name_label}.${data.azurerm_resource_group.rg_terraform.location}.cloudapp.azure.com"
}

output "terraform_public_ip_address" {
  value = "${data.azurerm_public_ip.pip_lnx1.ip_address}"
}

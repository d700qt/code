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

  security_rule {
    name                       = "http_bamboo"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "8085"
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
  domain_name_label            = "adeweetman-ci1"

  tags {
    environment = "dev"
  }
}

output "terraform_public_ip_address" {
  value = "${azurerm_public_ip.pip_terraform.ip_address}"
}

output "terraform_public_fqdn" {
  value = "${azurerm_public_ip.pip_terraform.domain_name_label}.${azurerm_resource_group.rg_terraform.location}.cloudapp.azure.com"
}

/*
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
*/

# Run terraform init -backend-config="backend.private" to switch backend type
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

  security_rule {
    name                       = "http_80"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags {
    environment = "global"
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

resource "azurerm_public_ip" "pip_ci1" {
  name                         = "pip_ci1"
  location                     = "${azurerm_resource_group.rg_terraform.location}"
  resource_group_name          = "${azurerm_resource_group.rg_terraform.name}"
  public_ip_address_allocation = "Static"
  idle_timeout_in_minutes      = 30
  domain_name_label            = "adeweetman-ci1"

  tags {
    environment = "global"
  }
}

resource "azurerm_public_ip" "pip_dev1" {
  name                         = "pip_dev1"
  location                     = "${azurerm_resource_group.rg_terraform.location}"
  resource_group_name          = "${azurerm_resource_group.rg_terraform.name}"
  public_ip_address_allocation = "Static"
  idle_timeout_in_minutes      = 30
  domain_name_label            = "adeweetman-dev1"

  tags {
    environment = "global"
  }
}

resource "azurerm_public_ip" "pip_win1" {
  name                         = "pip_win1"
  location                     = "${azurerm_resource_group.rg_terraform.location}"
  resource_group_name          = "${azurerm_resource_group.rg_terraform.name}"
  public_ip_address_allocation = "Static"
  idle_timeout_in_minutes      = 30
  domain_name_label            = "adeweetman-win1"

  tags {
    environment = "uat"
  }
}

resource "azurerm_public_ip" "pip_win2" {
  name                         = "pip_win2"
  location                     = "${azurerm_resource_group.rg_terraform.location}"
  resource_group_name          = "${azurerm_resource_group.rg_terraform.name}"
  public_ip_address_allocation = "Static"
  idle_timeout_in_minutes      = 30
  domain_name_label            = "adeweetman-win2"

  tags {
    environment = "prod"
  }
}

output "ci1_public_ip_address" {
  value = "${azurerm_public_ip.pip_ci1.ip_address}"
}

output "ci1_public_fqdn" {
  value = "${azurerm_public_ip.pip_ci1.domain_name_label}.${azurerm_resource_group.rg_terraform.location}.cloudapp.azure.com"
}

output "dev1_public_ip_address" {
  value = "${azurerm_public_ip.pip_dev1.ip_address}"
}

output "dev1_public_fqdn" {
  value = "${azurerm_public_ip.pip_dev1.domain_name_label}.${azurerm_resource_group.rg_terraform.location}.cloudapp.azure.com"
}

output "win1_public_ip_address" {
  value = "${azurerm_public_ip.pip_win1.ip_address}"
}

output "win1_public_fqdn" {
  value = "${azurerm_public_ip.pip_win1.domain_name_label}.${azurerm_resource_group.rg_terraform.location}.cloudapp.azure.com"
}

output "win2_public_ip_address" {
  value = "${azurerm_public_ip.pip_win2.ip_address}"
}

output "win2_public_fqdn" {
  value = "${azurerm_public_ip.pip_win2.domain_name_label}.${azurerm_resource_group.rg_terraform.location}.cloudapp.azure.com"
}

/*
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
*/

# based on https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-install-configure

resource "azurerm_resource_group" "test" {
  name     = "acctestrg"
  location = "West US 2"
}




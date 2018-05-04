/*
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
*/

resource "azurerm_resource_group" "test" {
  name     = "acctestrg"
  location = "West US 2"
}




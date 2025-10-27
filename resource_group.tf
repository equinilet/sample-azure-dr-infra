resource "azurerm_resource_group" "primary" {
  provider = azurerm.owner

  name     = "dr-sample-prim"
  location = var.primary_region
}

resource "azurerm_resource_group" "secondary" {
  provider = azurerm.owner

  name     = "dr-sample-sec"
  location = var.secondary_region
}


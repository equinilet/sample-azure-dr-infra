resource "azurerm_virtual_network" "primary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location

  name          = "primary"
  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "vm_primary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.primary.name

  name                 = "vm_primary"
  virtual_network_name = azurerm_virtual_network.primary.name
  address_prefixes     = ["10.0.0.0/24"] // 10.0.0.0 - 10.0.0.255
}

resource "azurerm_virtual_network" "secondary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name
  location            = azurerm_resource_group.secondary.location

  name          = "secondary"
  address_space = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "vm_secondary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name

  name                 = "vm_secondary"
  virtual_network_name = azurerm_virtual_network.secondary.name
  address_prefixes     = ["10.2.0.0/24"] // 10.2.0.0 - 10.2.0.255
}

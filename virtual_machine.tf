resource "azurerm_public_ip" "vm_primary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  
  name                = "primaryVmPublic"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm_primary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location

  name = "primary-vm"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_primary.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vm_primary.id
  }
}

resource "azurerm_network_security_group" "vm_primary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  
  name                = "vm-primary"

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "rdp"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "iis"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8172"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }    
}

resource "azurerm_network_interface_security_group_association" "vm_primary" {
  provider = azurerm.owner

  network_interface_id      = azurerm_network_interface.vm_primary.id
  network_security_group_id = azurerm_network_security_group.vm_primary.id
}

resource "azurerm_windows_virtual_machine" "vm_primary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location

  name = "vm-primary"
  size = "Standard_F2"
  vm_agent_platform_updates_enabled                      = true
  
  admin_username = "adminuser"
  admin_password = "P@$$w0rd1234!"

  network_interface_ids = [
    azurerm_network_interface.vm_primary.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = "/subscriptions/237800a4-7cc7-4b4a-8f5e-660d79739d1f/resourceGroups/dr-sample-prim/providers/Microsoft.Compute/galleries/sample_dr_gallery/images/adventureworks-sample/versions/1.1.0"
  
  #  source_image_reference {
  #   publisher = "MicrosoftWindowsServer"
  #   offer     = "WindowsServer"
  #   sku       = "2022-Datacenter"
  #   version   = "latest"
  # }
}

resource "azurerm_public_ip" "vm_secondary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name
  location            = azurerm_resource_group.secondary.location
  
  name                = "secondaryVmPublic"
  allocation_method   = "Static"
}

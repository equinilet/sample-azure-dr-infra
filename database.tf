resource "azurerm_mssql_server" "primary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location

  name    = "drexamplemsqlprim"
  version = "12.0"

  administrator_login          = "Admin2025"
  administrator_login_password = "RootPass2025!!"
}

resource "azurerm_mssql_firewall_rule" "vm_primary_internal" {
  provider            = azurerm.owner  
  name             = "AllowVmPrimaryInternal"
  server_id        = azurerm_mssql_server.primary.id
  
  start_ip_address = azurerm_network_interface.vm_primary.private_ip_address
  end_ip_address   = azurerm_network_interface.vm_primary.private_ip_address
}

resource "azurerm_mssql_firewall_rule" "vm_primary_public" {
  provider         = azurerm.owner
  name             = "AllowVmPrimaryPublic"
  server_id        = azurerm_mssql_server.primary.id
  
  start_ip_address = azurerm_public_ip.vm_primary.ip_address
  end_ip_address   = azurerm_public_ip.vm_primary.ip_address
}

resource "azurerm_mssql_elasticpool" "primary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location

  name         = "mssql-epool-prim"
  server_name  = azurerm_mssql_server.primary.name
  license_type = "LicenseIncluded"
  max_size_gb  = 20

  sku {
    name     = "GP_Gen5"
    tier     = "GeneralPurpose"
    family   = "Gen5"
    capacity = 4
  }

  zone_redundant = true

  per_database_settings {
    min_capacity = 0.25
    max_capacity = 4
  }
}

resource "azurerm_mssql_server" "secondary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name
  location            = azurerm_resource_group.secondary.location

  name    = "drexamplemsqlsec"
  version = "12.0"

  administrator_login          = "Admin2025"
  administrator_login_password = "RootPass2025!!"
}

resource "azurerm_mssql_elasticpool" "secondary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name
  location            = azurerm_resource_group.secondary.location

  name         = "mssql-epool-sec"
  server_name  = azurerm_mssql_server.secondary.name
  license_type = "LicenseIncluded"
  max_size_gb  = 20

  sku {
    name     = "GP_Gen5"
    tier     = "GeneralPurpose"
    family   = "Gen5"
    capacity = 4
  }

  zone_redundant = false

  per_database_settings {
    min_capacity = 0.25
    max_capacity = 4
  }
}

resource "azurerm_mssql_database" "primary_db1" {
  provider = azurerm.owner

  name            = "example-db"
  server_id       = azurerm_mssql_server.primary.id
  elastic_pool_id = azurerm_mssql_elasticpool.primary.id
  create_mode     = "Default"

  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"

  sku_name       = "ElasticPool"
  min_capacity   = 0
  max_size_gb    = 5
  zone_redundant = true

  sample_name = "AdventureWorksLT"

  lifecycle {
    prevent_destroy = false
  }
}

resource "azurerm_mssql_database" "secondary_db1" {
  provider = azurerm.owner

  name                        = "example-db-sec"
  server_id                   = azurerm_mssql_server.secondary.id
  elastic_pool_id             = azurerm_mssql_elasticpool.secondary.id
  create_mode                 = "Secondary"
  creation_source_database_id = azurerm_mssql_database.primary_db1.id

  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"

  //sku_name     = "ElasticPool"  
  min_capacity   = 0
  zone_redundant = false

  lifecycle {
    prevent_destroy = false
  }
}

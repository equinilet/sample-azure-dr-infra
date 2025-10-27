resource "azurerm_recovery_services_vault" "vault" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name
  location            = azurerm_resource_group.secondary.location

  name = "example-recovery-vault"
  sku  = "Standard"
}

resource "random_id" "vault_storage_account" {
  keepers = {
    vault_id = azurerm_recovery_services_vault.vault.id
  }

  byte_length = 8
}

resource "azurerm_storage_account" "site_recovery" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location

  name                     = "sr${random_id.vault_storage_account.hex}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_site_recovery_fabric" "primary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name
  location            = azurerm_resource_group.primary.location

  name                = "primary-fabric"
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
}

resource "azurerm_site_recovery_protection_container" "primary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name

  name                 = "primary-protection-container"
  recovery_vault_name  = azurerm_recovery_services_vault.vault.name
  recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
}

resource "azurerm_site_recovery_fabric" "secondary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name
  location            = azurerm_resource_group.secondary.location

  name                = "secondary-fabric"
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
}

resource "azurerm_site_recovery_protection_container" "secondary" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name

  name                 = "secondary-protection-container"
  recovery_vault_name  = azurerm_recovery_services_vault.vault.name
  recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
}

resource "azurerm_site_recovery_replication_policy" "policy" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name

  name                                                 = "policy"
  recovery_vault_name                                  = azurerm_recovery_services_vault.vault.name
  recovery_point_retention_in_minutes                  = 24 * 60
  application_consistent_snapshot_frequency_in_minutes = 4 * 60
}

resource "azurerm_site_recovery_protection_container_mapping" "container-mapping" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name

  name = "container-mapping"

  recovery_vault_name = azurerm_recovery_services_vault.vault.name

  recovery_fabric_name                      = azurerm_site_recovery_fabric.primary.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name

  recovery_target_protection_container_id = azurerm_site_recovery_protection_container.secondary.id
  recovery_replication_policy_id          = azurerm_site_recovery_replication_policy.policy.id
}

resource "azurerm_site_recovery_network_mapping" "network-mapping" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name

  name = "network-mapping"

  recovery_vault_name = azurerm_recovery_services_vault.vault.name

  source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name

  source_network_id = azurerm_virtual_network.primary.id
  target_network_id = azurerm_virtual_network.secondary.id
}

resource "azurerm_site_recovery_replicated_vm" "vm-replication" {
  provider            = azurerm.owner
  resource_group_name = azurerm_resource_group.secondary.name

  name = "vm-replication"

  recovery_vault_name                       = azurerm_recovery_services_vault.vault.name
  source_recovery_fabric_name               = azurerm_site_recovery_fabric.primary.name
  source_vm_id                              = azurerm_windows_virtual_machine.vm_primary.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id
  source_recovery_protection_container_name = azurerm_site_recovery_protection_container.primary.name

  target_resource_group_id                = azurerm_resource_group.secondary.id
  target_recovery_fabric_id               = azurerm_site_recovery_fabric.secondary.id
  target_recovery_protection_container_id = azurerm_site_recovery_protection_container.secondary.id

  managed_disk {
    disk_id                    = azurerm_windows_virtual_machine.vm_primary.os_disk[0].id
    staging_storage_account_id = azurerm_storage_account.site_recovery.id
    target_resource_group_id   = azurerm_resource_group.secondary.id
    target_disk_type           = "Premium_LRS"
    target_replica_disk_type   = "Premium_LRS"
  }

  network_interface {
    source_network_interface_id   = azurerm_network_interface.vm_primary.id
    target_subnet_name            = azurerm_subnet.vm_secondary.name
    recovery_public_ip_address_id = azurerm_public_ip.vm_secondary.id
  }

  depends_on = [
    azurerm_site_recovery_protection_container_mapping.container-mapping,
    azurerm_site_recovery_network_mapping.network-mapping,
  ]
}

resource "azurerm_site_recovery_replication_recovery_plan" "sample" {
  provider = azurerm.owner

  name = "example-recover-plan"

  recovery_vault_id         = azurerm_recovery_services_vault.vault.id
  source_recovery_fabric_id = azurerm_site_recovery_fabric.primary.id
  target_recovery_fabric_id = azurerm_site_recovery_fabric.secondary.id

  shutdown_recovery_group {}

  failover_recovery_group {}

  boot_recovery_group {
    replicated_protected_items = [azurerm_site_recovery_replicated_vm.vm-replication.id]
  }

}

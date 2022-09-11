locals {
  key_vault_name = join("", split("-", var.md_metadata.name_prefix))

  paired_region_map = {
    "westus"         = "eastus"
    "eastus"         = "westus"
    "westus3"        = "eastus2"
    "eastus2"        = "westus3"
    "southcentralus" = "northcentralus"
    "northcentralus" = "southcentralus"
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.md_metadata.name_prefix
  location = var.vnet.specs.azure.region

  tags = var.md_metadata.default_tags
}

data "azuread_service_principal" "main" {
  application_id = var.azure_service_principal.data.client_id
}

resource "azurerm_key_vault" "main" {
  name                            = local.key_vault_name
  location                        = var.vnet.specs.azure.region
  resource_group_name             = azurerm_resource_group.main.name
  tenant_id                       = var.azure_service_principal.data.tenant_id
  sku_name                        = "standard"
  soft_delete_retention_days      = 7
  purge_protection_enabled        = true
  enabled_for_template_deployment = true

  access_policy {
    tenant_id = var.azure_service_principal.data.tenant_id
    object_id = data.azuread_service_principal.main.object_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Update",
      "Import",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "Purge",
      "WrapKey",
      "UnwrapKey"
    ]
  }

  access_policy {
    tenant_id = var.azure_service_principal.data.tenant_id
    # This object ID is a static object ID for Azure Cosmos DB: https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-setup-cmk#add-access-policy
    object_id = "a9e12b7f-f218-4b82-8697-7352c51fbb4c"

    key_permissions = [
      "Get",
      "List",
      "Import",
      "WrapKey",
      "UnwrapKey"
    ]
  }

  tags = var.md_metadata.default_tags
}

resource "azurerm_key_vault_key" "main" {
  name         = local.key_vault_name
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "unwrapKey",
    "wrapKey"
  ]
}

resource "azurerm_cosmosdb_account" "main" {
  name                               = var.md_metadata.name_prefix
  location                           = azurerm_resource_group.main.location
  resource_group_name                = azurerm_resource_group.main.name
  offer_type                         = "Standard"
  kind                               = "MongoDB"
  is_virtual_network_filter_enabled  = true
  public_network_access_enabled      = false
  access_key_metadata_writes_enabled = false
  key_vault_key_id                   = azurerm_key_vault_key.main.versionless_id

  enable_automatic_failover       = var.geo_redundancy.automatic_failover
  enable_multiple_write_locations = var.geo_redundancy.multi_region_writes
  mongo_server_version            = var.database.mongo_server_version

  # If we wanted to use RBAC instead of access policies for CMK, we would need to set up a two-step deployment for:
  # default_identity_type = "SystemAssignedIdentity"
  identity {
    type = "SystemAssigned"
  }

  virtual_network_rule {
    id = azurerm_subnet.main.id
  }

  dynamic "capabilities" {
    for_each = var.database.serverless ? toset(["enabled"]) : toset([])
    content {
      name = "EnableServerless"
    }
  }

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  capacity {
    total_throughput_limit = var.database.total_throughput_limit
  }

  consistency_policy {
    consistency_level       = var.database.consistency_level
    max_interval_in_seconds = var.database.max_interval_in_seconds
    max_staleness_prefix    = var.database.max_staleness_prefix
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  dynamic "geo_location" {
    for_each = var.database.serverless ? toset([]) : toset(["enabled"])
    content {
      location          = local.paired_region_map[azurerm_resource_group.main.location]
      failover_priority = 1
    }
  }

  dynamic "geo_location" {
    for_each = { for ar in var.geo_redundancy.additional_regions : ar.location => ar }
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
    }
  }

  dynamic "backup" {
    for_each = var.backups.backup_type == "Continuous" ? toset(["Continuous"]) : toset([])
    content {
      type = var.backups.backup_type
    }
  }

  dynamic "backup" {
    for_each = var.backups.backup_type == "Periodic" ? toset(["Periodic"]) : toset([])
    content {
      type                = var.backups.backup_type
      interval_in_minutes = var.backups.interval
      retention_in_hours  = var.backups.retention
      storage_redundancy  = var.backups.redundancy
    }
  }

  tags = var.md_metadata.default_tags
}

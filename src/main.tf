locals {
  # This can only be set to standard, and is required to be set.
  offer_type = "Standard"
  kind       = "MongoDB"

  capabilities = {
    enable_mongo                = "EnableMongo"
    mongo_version               = "MongoDBv3.4"
    mongo_enable_doc_level      = "mongoEnableDocLevelTTL"
    enable_aggregation_pipeline = "EnableAggregationPipeline"
  }
  consistency_policy = {
    # Must be greater than 300 when more than one geo location is used.
    max_interval_in_seconds = 400
    # Must be greater than 100000 when more than one geo location is used.
    max_staleness_prefix = 150000
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.md_metadata.name_prefix
  location = var.vnet.specs.azure.region
}

resource "azurerm_cosmosdb_account" "main" {
  name                              = var.md_metadata.name_prefix
  location                          = azurerm_resource_group.main.location
  resource_group_name               = azurerm_resource_group.main.name
  offer_type                        = local.offer_type
  kind                              = local.kind
  is_virtual_network_filter_enabled = true

  enable_automatic_failover       = var.redundancy.automatic_failover
  enable_multiple_write_locations = var.database.multi_region_writes
  mongo_server_version            = var.database.mongo_server_version

  virtual_network_rule {
    id = var.vnet.data.infrastructure.default_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "capabilities" {
    for_each = var.database.serverless ? toset(["enabled"]) : toset([])
    content {
      name = "EnableServerless"
    }
  }

  capabilities {
    name = local.capabilities.enable_aggregation_pipeline
  }

  capabilities {
    name = local.capabilities.mongo_enable_doc_level
  }

  capabilities {
    name = local.capabilities.mongo_version
  }

  capabilities {
    name = local.capabilities.enable_mongo
  }

  capacity {
    total_throughput_limit = var.database.total_throughput_limit
  }

  consistency_policy {
    # Mongo only supports strong, bounded staleness, and eventual consistency.
    consistency_level       = var.database.consistency_level
    max_interval_in_seconds = local.consistency_policy.max_interval_in_seconds
    max_staleness_prefix    = local.consistency_policy.max_staleness_prefix
  }

  # Primary region - zone redundancy not supported in West US or North Central US currently
  geo_location {
    location          = var.redundancy.primary_region.location
    failover_priority = 0
    zone_redundant    = var.redundancy.primary_region.zone_redundant
  }

  # Additional regions - zone redundancy not supported in West US or North Central US currently
  dynamic "geo_location" {
    for_each = var.redundancy.additional_regions
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }

  # Need to solve for continuous backup setting
  dynamic "backup" {
    for_each = var.backups.enable_backup ? toset(["enabled"]) : toset([])
    content {
      type                = var.backups.backup_type
      interval_in_minutes = var.backups.interval
      retention_in_hours  = var.backups.retention
      storage_redundancy  = var.backups.redundancy
    }
  }
}

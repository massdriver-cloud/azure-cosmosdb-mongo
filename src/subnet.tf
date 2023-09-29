locals {
  split_vnet_id       = split("/", var.azure_virtual_network.data.infrastructure.id)
  vnet_name           = element(local.split_vnet_id, length(local.split_vnet_id) - 1)
  vnet_resource_group = element(local.split_vnet_id, index(local.split_vnet_id, "resourceGroups") + 1)
  cidr                = var.network.auto ? utility_available_cidr.cidr.result : var.network.cidr
}

data "azurerm_virtual_network" "lookup" {
  name                = local.vnet_name
  resource_group_name = local.vnet_resource_group
}

data "azurerm_subnet" "lookup" {
  for_each             = toset(data.azurerm_virtual_network.lookup.subnets)
  name                 = each.key
  virtual_network_name = local.vnet_name
  resource_group_name  = local.vnet_resource_group
}

resource "utility_available_cidr" "cidr" {
  from_cidrs = data.azurerm_virtual_network.lookup.address_space
  used_cidrs = flatten([for subnet in data.azurerm_subnet.lookup : subnet.address_prefixes])
  mask       = 28
}

resource "azurerm_subnet" "main" {
  name                 = var.md_metadata.name_prefix
  resource_group_name  = local.vnet_resource_group
  virtual_network_name = local.vnet_name
  address_prefixes     = [local.cidr]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
}

resource "azurerm_private_dns_zone" "privatelink" {
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = local.vnet_resource_group
  tags                = var.md_metadata.default_tags
}

resource "azurerm_private_endpoint" "default" {
  name                = "${var.md_metadata.name_prefix}-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main.id

  private_service_connection {
    name                           = "${var.md_metadata.name_prefix}-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    subresource_names              = ["MongoDB"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink.id]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "default" {
  name                  = "${var.md_metadata.name_prefix}-vnl"
  resource_group_name   = local.vnet_resource_group
  private_dns_zone_name = azurerm_private_dns_zone.privatelink.name
  virtual_network_id    = data.azurerm_virtual_network.lookup.id
  registration_enabled  = true
  tags                  = var.md_metadata.default_tags
}

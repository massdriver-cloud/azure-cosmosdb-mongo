locals {
  split_vnet_id       = split("/", var.azure_virtual_network.data.infrastructure.id)
  vnet_name           = element(local.split_vnet_id, length(local.split_vnet_id) - 1)
  vnet_resource_group = element(local.split_vnet_id, index(local.split_vnet_id, "resourceGroups") + 1)
}

resource "azurerm_subnet" "main" {
  name                 = var.md_metadata.name_prefix
  resource_group_name  = local.vnet_resource_group
  virtual_network_name = local.vnet_name
  address_prefixes     = [var.database.cidr]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
}

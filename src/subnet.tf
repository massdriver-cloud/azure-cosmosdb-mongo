locals {
  split_vnet_id       = split("/", var.vnet.data.infrastructure.id)
  vnet_name           = element(local.split_vnet_id, length(local.split_vnet_id) - 1)
  vnet_resource_group = element(local.split_vnet_id, index(local.split_vnet_id, "resourceGroups") + 1)
}

resource "azurerm_subnet" "main" {
  name                 = var.md_metadata.name_prefix
  resource_group_name  = local.vnet_resource_group
  virtual_network_name = local.vnet_name
  address_prefixes     = [var.database.cidr]
  service_endpoints    = ["Microsoft.AzureCosmosDB", "Microsoft.KeyVault"]
}

resource "azurerm_private_endpoint" "main" {
  name                = var.md_metadata.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = var.vnet.specs.azure.region
  subnet_id           = azurerm_subnet.main.id
  tags                = var.md_metadata.default_tags

  private_service_connection {
    name                           = "key-vault"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
  }
}

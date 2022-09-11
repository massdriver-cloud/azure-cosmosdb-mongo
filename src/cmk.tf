data "azuread_service_principal" "main" {
  application_id = var.azure_service_principal.data.client_id
}

resource "azurerm_key_vault" "main" {
  name                            = join("", split("-", var.md_metadata.name_prefix))
  location                        = var.vnet.specs.azure.region
  resource_group_name             = azurerm_resource_group.main.name
  tenant_id                       = var.azure_service_principal.data.tenant_id
  sku_name                        = "standard"
  soft_delete_retention_days      = 90
  purge_protection_enabled        = true
  enabled_for_template_deployment = true

  access_policy {
    tenant_id = var.azure_service_principal.data.tenant_id
    # This access policy is required to allow the provisioner service principal to create the key vault key and set key permissions for other identities.
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
    # This object ID is a global object ID for the Azure Cosmos DB resource: https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-setup-cmk#add-access-policy
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
  name         = azurerm_key_vault.main.name
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "unwrapKey",
    "wrapKey"
  ]
}
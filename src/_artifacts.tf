locals {
  data_infrastructure = {
    ari = azurerm_cosmosdb_account.main.id
  }
  data_authentication = {
    username = "${var.md_metadata.name_prefix}"
    password = azurerm_cosmosdb_account.main.primary_key
    hostname = "${var.md_metadata.name_prefix}.mongo.cosmos.azure.com"
    port     = 10255
  }
}

resource "massdriver_artifact" "authentication" {
  field                = "mongo_authentication"
  provider_resource_id = azurerm_cosmosdb_account.main.id
  name                 = "CosmosDB Mongo Server ${var.md_metadata.name_prefix} (${azurerm_cosmosdb_account.main.id})"
  artifact = jsonencode(
    {
      data = {
        infrastructure = local.data_infrastructure
        authentication = local.data_authentication
      }
      specs = {
        mongo = {
          version = azurerm_cosmosdb_account.main.mongo_server_version
        }
      }
    }
  )
}

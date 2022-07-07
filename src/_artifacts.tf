# locals {
#   data_infrastructure = {
#     ari = azurerm_cosmosdb_account.main.id
#   }
#   data_authentication = {
#     username = "${var.md_metadata.name_prefix}"
#     password = azurerm_cosmosdb_account.main.primary_key
#     hostname = "${var.md_metadata.name_prefix}.mongo.cosmos.azure.com"
#     port     = 10255
#   }
#   data_security = {}
# }

# resource "massdriver_artifact" "authentication" {
#   field                = "authentication"
#   provider_resource_id = azurerm_cosmosdb_account.main.id
#   name                 = "CosmosDB Server ${var.md_metadata.name_prefix} (${azurerm_cosmosdb_account.main.id})"
#   artifact = jsonencode(
#     {
#       data = {
#         infrastructure = local.data_infrastructure
#         authentication = local.data_authentication
#         security       = local.data_security
#       }
#       specs = {
#         azure = {
#           region = azurerm_resource_group.main.location
#         }
#       }
#     }
#   )
# }

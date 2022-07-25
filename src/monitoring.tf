locals {
  scope_config = {
    severity    = "1"
    frequency   = "PT1M"
    window_size = "PT5M"
  }
  metric_config = {
    operator              = "GreaterThan"
    aggregation           = "Average"
    threshold_consumption = 90
    threshold_latency     = 100
  }
}

module "alarm_channel" {
  source              = "github.com/massdriver-cloud/terraform-modules//azure-alarm-channel?ref=40d6e54"
  md_metadata         = var.md_metadata
  resource_group_name = azurerm_resource_group.main.name
}

module "normalized_ru_consumption_metric_alert" {
  source                  = "github.com/massdriver-cloud/terraform-modules//azure-monitor-metrics-alarm?ref=40d6e54"
  scopes                  = [azurerm_cosmosdb_account.main.id]
  resource_group_name     = azurerm_resource_group.main.name
  monitor_action_group_id = module.alarm_channel.id
  severity                = local.scope_config.severity
  frequency               = local.scope_config.frequency
  window_size             = local.scope_config.window_size

  depends_on = [
    azurerm_cosmosdb_account.main
  ]

  md_metadata  = var.md_metadata
  display_name = "RU Usage"
  message      = "High RU Usage"

  alarm_name       = "${var.md_metadata.name_prefix}-highRUUsage"
  operator         = local.metric_config.operator
  metric_name      = "NormalizedRUConsumption"
  metric_namespace = "Microsoft.documentdb/databaseaccounts"
  aggregation      = local.metric_config.aggregation
  threshold        = local.metric_config.threshold_consumption
}

module "server_latency_metric_alert" {
  source                  = "github.com/massdriver-cloud/terraform-modules//azure-monitor-metrics-alarm?ref=40d6e54"
  scopes                  = [azurerm_cosmosdb_account.main.id]
  resource_group_name     = azurerm_resource_group.main.name
  monitor_action_group_id = module.alarm_channel.id
  severity                = local.scope_config.severity
  frequency               = local.scope_config.frequency
  window_size             = local.scope_config.window_size

  depends_on = [
    azurerm_cosmosdb_account.main
  ]

  md_metadata  = var.md_metadata
  display_name = "Server Latency"
  message      = "High Server Latency"

  alarm_name       = "${var.md_metadata.name_prefix}-highServerLatency"
  operator         = local.metric_config.operator
  metric_name      = "ServerSideLatency"
  metric_namespace = "Microsoft.documentdb/databaseaccounts"
  aggregation      = local.metric_config.aggregation
  threshold        = local.metric_config.threshold_latency
}

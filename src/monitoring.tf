locals {
  automated_alarms = {
    normalized_ru_consumption_metric_alert = {
      severity    = "1"
      frequency   = "PT1M"
      window_size = "PT5M"
      operator    = "GreaterThan"
      aggregation = "Average"
      threshold   = 90
    }
    server_latency_metric_alert = {
      severity    = "1"
      frequency   = "PT1M"
      window_size = "PT5M"
      operator    = "GreaterThan"
      aggregation = "Average"
      threshold   = 500
    }
  }
  alarms_map = {
    "AUTOMATED" = local.automated_alarms
    "DISABLED"  = {}
    "CUSTOM"    = lookup(var.monitoring, "alarms", {})
  }
  alarms = lookup(local.alarms_map, var.monitoring.mode, {})
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
  severity                = local.alarms.normalized_ru_consumption_metric_alert.severity
  frequency               = local.alarms.normalized_ru_consumption_metric_alert.frequency
  window_size             = local.alarms.normalized_ru_consumption_metric_alert.window_size

  depends_on = [
    azurerm_cosmosdb_account.main
  ]

  md_metadata  = var.md_metadata
  display_name = "RU Usage"
  message      = "High RU Usage"

  alarm_name       = "${var.md_metadata.name_prefix}-highRUUsage"
  operator         = local.alarms.normalized_ru_consumption_metric_alert.operator
  metric_name      = "NormalizedRUConsumption"
  metric_namespace = "Microsoft.documentdb/databaseaccounts"
  aggregation      = local.alarms.normalized_ru_consumption_metric_alert.aggregation
  threshold        = local.alarms.normalized_ru_consumption_metric_alert.threshold
}

module "server_latency_metric_alert" {
  source                  = "github.com/massdriver-cloud/terraform-modules//azure-monitor-metrics-alarm?ref=40d6e54"
  scopes                  = [azurerm_cosmosdb_account.main.id]
  resource_group_name     = azurerm_resource_group.main.name
  monitor_action_group_id = module.alarm_channel.id
  severity                = local.alarms.server_latency_metric_alert.severity
  frequency               = local.alarms.server_latency_metric_alert.frequency
  window_size             = local.alarms.server_latency_metric_alert.window_size

  depends_on = [
    azurerm_cosmosdb_account.main
  ]

  md_metadata  = var.md_metadata
  display_name = "Server Latency"
  message      = "High Server Latency"

  alarm_name       = "${var.md_metadata.name_prefix}-highServerLatency"
  operator         = local.alarms.server_latency_metric_alert.operator
  metric_name      = "ServerSideLatency"
  metric_namespace = "Microsoft.documentdb/databaseaccounts"
  aggregation      = local.alarms.server_latency_metric_alert.aggregation
  threshold        = local.alarms.server_latency_metric_alert.threshold
}

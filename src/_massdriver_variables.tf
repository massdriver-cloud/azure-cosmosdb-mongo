// Auto-generated variable declarations from massdriver.yaml
variable "azure_service_principal" {
  type = object({
    data = object({
      client_id       = string
      client_secret   = string
      subscription_id = string
      tenant_id       = string
    })
    specs = object({})
  })
}
variable "azure_virtual_network" {
  type = object({
    data = object({
      infrastructure = object({
        cidr              = string
        default_subnet_id = string
        id                = string
      })
    })
    specs = optional(object({
      azure = optional(object({
        region = string
      }))
    }))
  })
}
variable "backups" {
  type = object({
    backup_type = optional(string)
    interval    = optional(number)
    redundancy  = optional(string)
    retention   = optional(number)
  })
}
variable "database" {
  type = object({
    consistency_level       = string
    mongo_server_version    = string
    serverless              = optional(bool)
    total_throughput_limit  = number
    max_interval_in_seconds = optional(number)
    max_staleness_prefix    = optional(number)
  })
}
variable "geo_redundancy" {
  type = object({
    additional_regions = optional(list(object({
      failover_priority = number
      location          = string
    })))
    automatic_failover  = optional(bool)
    multi_region_writes = optional(bool)
  })
}
variable "md_metadata" {
  type = object({
    default_tags = object({
      managed-by  = string
      md-manifest = string
      md-package  = string
      md-project  = string
      md-target   = string
    })
    deployment = object({
      id = string
    })
    name_prefix = string
    observability = object({
      alarm_webhook_url = string
    })
    package = object({
      created_at             = string
      deployment_enqueued_at = string
      previous_status        = string
      updated_at             = string
    })
    target = object({
      contact_email = string
    })
  })
}
variable "monitoring" {
  type = object({
    mode = optional(string)
    alarms = optional(object({
      normalized_ru_consumption_metric_alert = optional(object({
        aggregation = string
        frequency   = string
        operator    = string
        severity    = number
        threshold   = number
        window_size = string
      }))
      server_latency_metric_alert = optional(object({
        aggregation = string
        frequency   = string
        operator    = string
        severity    = number
        threshold   = number
        window_size = string
      }))
    }))
  })
}
variable "network" {
  type = object({
    auto = optional(bool)
    cidr = optional(string)
  })
}

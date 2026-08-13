variable "azure" {
  type = object({
    resource_group_name = string
    location            = string
    tags                = map(string)
  })
}

variable "name" {
  type        = string
  description = "Name of the Azure Redis Cache"
}

variable "redis_configs" {
  type = object({
    capacity = number
    family    = string
    sku_name  = string
    non_ssl_port_enabled = bool
    minimum_tls_version  = string
    redis_version = string
    patch_schedule = map(string)
  })
  default = {
    capacity = 2
    family = "C"
    sku_name = "Standard"
    non_ssl_port_enabled = false
    minimum_tls_version  = "1.2"
    redis_version = "6"
    patch_schedule = {
      day_of_week = "Saturday"
      start_hour_utc = "4" # last 5 hours
    }
  }
}

variable "private_endpoint" {
  type = object({
    dns_zone_id_prefix = string
    subnet_id          = string
  })
  description = "Private Endpoint Config"
}

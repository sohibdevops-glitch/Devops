variable "azure" {
  type = object({
    location            = string
    resource_group_name = string
    tags                = map(string)
  })
  description = "AZURE settings (location and resource group name)."
}

variable "name" {
  type        = string
  description = "Name of the App Configuration"
}

variable "sku" {
  type        = string
  description = "SKU of the App Configuration"
  validation {
    condition     = contains(["basic", "standard", "premium"], var.sku)
    error_message = "The SKU must be one of the following: basic, standard, premium."
  }
}

variable "private_endpoint" {
  type = object({
    dns_zone_id_prefix = string
    subnet_id          = string
  })
  description = "Private Endpoint Config"
}

variable "app_config_key_value" {
  description = "Key-value pairs for app configuration. Value will be json encoded."
  type        = map(any)
}

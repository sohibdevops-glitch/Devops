variable "azure" {
  type = object({
    tenant_id           = string
    resource_group_name = string
    location            = string
    tags                = map(string)
  })
}

variable "name" {
  type        = string
  description = "Name of the key vault"
}

variable "private_endpoint" {
  type = object({
    dns_zone_id_prefix = string
    subnet_id          = string
  })
  description = "Private Endpoint Config"
  default     = null
}

variable "sku" {
  type    = string
  default = "standard"
  validation {
    condition     = (contains(["standard", "premium"], lower(var.sku)))
    error_message = "The sku should be standard or premium."
  }
}

variable "permissions" {
  type = map(object({
    object_id = string
    # Secrets
    manage_secrets = optional(bool, false)
    get_secrets    = optional(bool, false)

    # Keys
    manage_keys = optional(bool, false)
    use_keys    = optional(bool, false)

    # Certificates
    manage_certificates = optional(bool, false)
    use_certificates    = optional(bool, false)
  }))
  default = {}
}


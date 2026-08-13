variable "azure" {
  type = object({
    resource_group_name = string
    location            = string
    tags                = map(string)
  })
}

variable "name" {
  type        = string
  description = "Name of the Azure Container Registry"
}

variable "admin_enabled" {
  type    = bool
  default = false
}

variable "private_endpoint" {
  type = object({
    dns_zone_id_prefix = string
    subnet_id          = string
  })
  description = "Private Endpoint Config"
}
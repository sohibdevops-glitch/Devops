variable "azure" {
  type = object({
    resource_group_name = string
    location            = string
    tags                = map(string)
  })
}

variable "name" {
  type        = string
  description = "Name of the servicebus namespace"
}

variable "capacity" {
  type        = number
  default     = 1
  description = "Premium Service bus only supports `capacity` of 1, 2, 4, 8 or 16"
}

variable "premium_messaging_partitions" {
  type        = number
  default     = 1
  description = "Premium Service bus only supports `premium_messaging_partitions` of 1, 2, 4"
}

variable "private_endpoint" {
  type = object({
    dns_zone_id_prefix = string
    subnet_id          = string
  })
  description = "Private Endpoint Config"
  default     = null
}

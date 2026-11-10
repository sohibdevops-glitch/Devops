# To create a private end point in Azure
variable "azure" {
  type = object({
    tenant_id           = string
    resource_group_name = string
    location            = string
    tags                = map(string)
  })
}

variable "private_endpoint" {
  type = object({
    pep_name                        = string
    private_connection_resource_id  = string
    subnet_id                       = string
    private_service_connection_name = string
  })
  description = "Private Endpoint Config"
  default     = null
}

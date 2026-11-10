variable "azure" {
  type = object({
    resource_group_name = string
    location            = string
    tags                = map(string)
  })
}

variable "name" {
  type        = string
  description = "Name of the key vault"
}

variable "managed_private_endpoints" {
  type = list(object({
    name               = string
    target_resource_id = string
    subresource_name   = string
  }))
  description = "List of Managed Private Endpoint Configs"
  default     = []
}

variable "github_configuration" {
  type = object({
    account_name       = string
    branch_name        = string
    git_url            = string
    publishing_enabled = bool
    repository_name    = string
    root_folder        = string
  })
  description = "ADF github configuration"
  default     = null
}

variable "azure" {
  type = object({
    resource_group_name = string
    location            = string
    tags                = map(string)
  })
}

variable "name" {
  type = string
  validation {
    condition     = length(var.name) <= 24
    error_message = "The storage name must not exceed 24 characters."
  }
}

variable "private_endpoint" {
  type = object({
    dns_zone_id_prefix = string
    subnet_id          = string
  })
  description = "Private Endpoint Config"
  default     = null
}

variable "storage_containers" {
  type        = set(string)
  default     = []
  description = "List of storage containers to create"
}

variable "file_shares" {
  type = map(object({
    quotaGB     = optional(number, 100)                    # Maximum size of the share, in gigabytes.
    access_tier = optional(string, "TransactionOptimized") # Possible values are Hot, Cool and TransactionOptimized, Premium.
  }))
  default     = {}
  description = "List of file shares to create"
}

variable "storage_tables" {
  type        = set(string)
  default     = []
  description = "List of storage tables to create"
}

variable "is_web" {
  type        = bool
  default     = false
  description = "Set to true, if the storage is for a static website."
}

variable "is_hns_enabled" {
  type        = bool
  default     = false
  description = "Enables Hierarchical Namespace Support for Azure Data Lake functionality."
}

variable "no_blob_private_endpoint" {
  type        = bool
  default     = false
  description = "Set to true to prevent the creation of a private endpoint for blob"
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Enables public network access."
}

variable "is_sftp_enabled" {
  type        = bool
  default     = false
  description = "Enables SFTP."
}

variable "custom_domain" {
  type    = string
  default = ""
}

variable "config" {
 type = object({
   account_replication_type         = optional(string, "LRS")
   cross_tenant_replication_enabled = optional(bool, true) # Enable by default at the moment
   # DR / object-level protection (opt-in per storage account)
   enable_versioning                    = optional(bool, false)
   enable_change_feed                   = optional(bool, false)
   blob_soft_delete_retention_days      = optional(number, null) # null = disabled
   container_soft_delete_retention_days = optional(number, null) # null = disabled
   point_in_time_restore_days           = optional(number, null) # null = disabled
 })
 default = {}
 validation {
   condition = (
     var.config.point_in_time_restore_days == null ||
     (
       var.config.enable_versioning &&
       var.config.enable_change_feed &&
       var.config.blob_soft_delete_retention_days != null &&
        try(var.config.point_in_time_restore_days < var.config.blob_soft_delete_retention_days, false)
     )
   )
   error_message = "point_in_time_restore_days requires enable_versioning=true, enable_change_feed=true, blob_soft_delete_retention_days set, and point_in_time_restore_days < blob_soft_delete_retention_days."
 }

}



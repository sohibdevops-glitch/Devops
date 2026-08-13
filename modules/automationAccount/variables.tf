variable "azure" {
  type = object({
    resource_group_name = string
    location            = string
    tags                = map(string)
  })
}

variable "name" {
  description = "Automation Account name"
  type        = string
}
variable "sku_name" {
  description = "Automation SKU (typically 'Basic')"
  type        = string
  default     = "Basic"
}

# ---------- Hybrid Runbook Worker on existing VM ----------
variable "vm_id" {
  description = "Resource ID of the existing VM to become a Hybrid Runbook Worker"
  type        = string
}

variable "hrw_group_name" {
  description = "Hybrid Runbook Worker Group name to create/use"
  type        = string
  default     = "hrw-default"
}

variable "worker_id" {
  description = "Specify the ID of this HybridWorker in UUID notation"
  type        = string
}

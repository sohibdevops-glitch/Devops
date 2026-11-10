# Define variables in `terraform.tfvars` or as environment variables: export TF_VAR_the_var_name=value (case matters)
variable "environment" {
  type        = string
  description = "Environment name. Either 'nonprod' or 'prod'"

  validation {
    condition     = contains(["nonprod", "prod"], var.environment)
    error_message = "The environment must be: 'nonprod' or 'prod'"
  }
}

variable "mongodb_public_key" {
  type        = string
  default     = null
  description = "MongoDB Atlas API Public Key. Can also be set with env. var.: MONGODB_ATLAS_PUBLIC_KEY"
}

variable "mongodb_private_key" {
  type        = string
  default     = null
  description = "MongoDB Atlas API Private Key. Can also be set with env. var.: MONGODB_ATLAS_PRIVATE_KEY"
  sensitive   = true
}

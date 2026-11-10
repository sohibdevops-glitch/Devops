# Define variables in `terraform.tfvars` or as environment variables: export TF_VAR_the_var_name=value (case matters)
variable "environment" {
  type        = string
  description = "Environment name. Either 'nonprod' or 'prod'"

  validation {
    condition     = contains(["nonprod", "prod"], var.environment)
    error_message = "The environment must be: 'nonprod' or 'prod'"
  }
}

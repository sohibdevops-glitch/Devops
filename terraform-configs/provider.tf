terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    # Cannot use variables here. So they have to be set in init command
    # resource_group_name  = ""
    # storage_account_name = ""
    container_name = "tfstate" # Created/managed by the other Terraform project

    # ⚠️ IMPORTANT !!! This is a different state file than the other Terraform project, but still in the same storage container
    key = "terraform-config.tfstate"
  }
}

provider "azurerm" {
  subscription_id = local.env_vars.azure_subscription_id

  features {
  }
}

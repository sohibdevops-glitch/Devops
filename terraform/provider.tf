terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.35.1"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }

  backend "azurerm" {
    # Cannot use variables here. So they have to be set in init command
    # resource_group_name  = ""
    # storage_account_name = ""
    container_name = "tfstate"
    key            = "terraform.tfstate"
  }
}

provider "azurerm" {
  subscription_id = local.env_vars.azure_subscription_id

  features {
  }
}

provider "azuread" {
}

provider "mongodbatlas" {
  private_key = var.mongodb_private_key
  public_key  = var.mongodb_public_key
}

provider "azapi" {
}

locals {
  # Tenant where is deployed terraform
  tenant_id = data.azurerm_client_config.current.tenant_id

  # ⚠️ For this Terraform project to work, you need to select the correct workspace
  #    Example: `terraform workspace select dev`
  subEnv = terraform.workspace == "default" ? "x" : terraform.workspace

  tenants = local.env_vars.sub_envs[local.subEnv].tenants

  resource_group_name = "${local.prefix.resource_group}-${local.subEnv}"

  prefix = {
    generic        = "rbg-b2c-winterfell-${local.env_vars.location_short}"
    resource_group = "rg-rbg-b2c-winterfell"
    keyvault       = "kv-rbg-b2c"
    storage        = "sarbgb2c"
  }

  envs = {
    # Non-Prod Subscription (DEV & UAT environments)
    nonprod = {
      azure_subscription_id = "0e214175-4bcd-4aad-9f6e-6c02fb1f277a" # mt-canada-b2c-nonprod

      location       = "Canada East"
      location_short = "caeast"

      sub_envs = {
        dev = {
          tenants = ["bp", "px", "up"]
        }

        uat = {
          tenants = ["bp", "px", "up"]
        }
      }
    }

    # Production Subscription (Prod environment)
    prod = {
      azure_subscription_id = "0d8f4db7-06d4-4f7f-9083-7827cff44449" # mck-canada-b2c-prod

      location       = "Canada Central"
      location_short = "cacentral"

      sub_envs = {
        preprd = {
          tenants = ["bp", "px", "up"]
        },
        prd = {
          tenants = ["bp", "px", "up"]
        }
      }
    }
  }

  env_vars = local.envs[var.environment]

  tags = {
    Note = "This resource is managed by Terraform"
  }
}

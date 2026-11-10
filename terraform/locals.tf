locals {
  # Tenant where is deployed terraform
  tenant_id = data.azurerm_client_config.current.tenant_id

  # MongoDB Atlas Organization ID (McKesson Canada B2C)
  mongodbatlas_organization_id = "67f5b80936fac70e68625e85"

  # For shared/common resources (this group should already exist or be created manually)
  main_resource_group_name = "${local.prefix.resource_group}-${var.environment == "prod" ? "prod-shared" : "nonprod"}"

  # Storage Account for Terraform state
  tfstate_storage_account_name = "rbgb2ctfstate${var.environment}" # Max. 24 char.

  prefix = {
    # To be used in naming convention: <azure service>-<product/application group>-<context>-<region>-<environment>
    generic = "rbg-b2c-winterfell-${local.env_vars.location_short}"

    # Should be rg-<product/applicationgroup>-<context>-<region>-<environment>
    resource_group = "rg-rbg-b2c-winterfell"

    # For storage accounts (prefix with sa...)
    storage = "sarbgb2c"

    # For key vault (prefix with kv...)
    keyvault = "kv-rbg-b2c"

    # For mongodb project
    mongodb_project = "rbg-b2c-winterfell"

    # For mongodb cluster (prefix with mdb)
    mongodb_cluster = "mdb-rbg-b2c"

    # Network Subnet
    subnet = "sb"

    # Network Security Group
    nsg = "nsg"
  }

  envs = {
    # Non-Prod Subscription (DEV & UAT environments)
    nonprod = {
      azure_subscription_id = "0e214175-4bcd-4aad-9f6e-6c02fb1f277a" # mt-canada-b2c-nonprod

      location       = "Canada East"
      location_short = "caeast"

      vnet = {
        # Address space
        # 10.200.29.128/25 (128 IPs)
        # 10.200.29.128 - 10.200.29.255
        # 10.200.31.0/24 (256 IPs)
        # 10.200.31.0 - 10.200.31.255
        resource_group_name = "rg-vnet-canadaeast-mt-canada-b2c-nonprod-gen1"
        name                = "vnet-canadaeast-mt-canada-b2c-nonprod"
      }

      subnets = {
        private_endpoints = "10.200.31.0/25" # (128 IPs) 10.200.31.0 - 10.200.31.127
      }

      # Used to assign KeyVault permissions
      object_ids = {
        sp_b2c_keyvault   = local.object_ids.sp_b2c_keyvault_as11574_nonprod
        sp_b2c_terraform  = local.object_ids.sp_b2c_terraform_as11574_nonprod
        contributor_group = local.object_ids.azure_mt_canada_b2c_nonprod_contributor
      }

      automation_account = {
        worker_id = "60e0d4c6-c025-4a81-a29f-0af8fdb328d8"
        vm_id     = "/subscriptions/0e214175-4bcd-4aad-9f6e-6c02fb1f277a/resourceGroups/rg-rbg-b2c-winterfell-nonprod/providers/Microsoft.Compute/virtualMachines/vmrbwnonceprod"
      }

      sub_envs = {
        # DEV configs
        dev = {
          tenants = ["bp", "px", "up"]

          mongodb = {
            node_count                      = 3
            instance_size                   = "M10"
            cloud_region                    = "CANADA_EAST"
            private_connection_resource_id  = "/subscriptions/0f12f5e2-f8df-4604-aa4d-204168e17941/resourceGroups/rg_68477d2c785cd577b17eaf35_5wfpvpsw/providers/Microsoft.Network/privateLinkServices/pls_6862953c8f846f4c1648f9af"
            private_service_connection_name = "pls_6862953c8f846f4c1648f9af"
          }

          web_custom_domains = {
            ask       =""# "ask-b2c-dev.mckesson.ca"
            tenant_bp =""# "monfidelo-b2c-dev.mckesson.ca"
            tenant_px =""#"groupeproxim-app-b2c-dev.mckesson.ca"
            tenant_up =""# "uniprix-app-b2c-dev.mckesson.ca"
          }

          automation_account = {
            worker_id = "8BAE8117-031D-42A0-8818-B9EF417BECAA"
            vm_id     = "/subscriptions/0e214175-4bcd-4aad-9f6e-6c02fb1f277a/resourceGroups/rg-rbg-b2c-winterfell-nonprod/providers/Microsoft.Compute/virtualMachines/vmrbwnonceprod"
          }
        }

        # UAT configs
        uat = {
          tenants = ["bp", "px", "up"]

          mongodb = {
            node_count                      = 3
            instance_size                   = "M10"
            cloud_region                    = "CANADA_EAST"
            private_connection_resource_id  = "/subscriptions/92f33102-54f1-4461-8891-fce9bcc03e64/resourceGroups/rg_68477d2c18c3b302ecbf5bed_lk671hkw/providers/Microsoft.Network/privateLinkServices/pls_6862edc48e8cfe711bf5afc2"
            private_service_connection_name = "pls_6862edc48e8cfe711bf5afc2"
          }

          web_custom_domains = {
            ask       = "" # "ask-b2c-uat.mckesson.ca"
            tenant_bp = "" # "monfidelo-b2c-uat.mckesson.ca"
            tenant_px = "" # "groupeproxim-app-b2c-uat.mckesson.ca"
            tenant_up = "" # "uniprix-app-b2c-uat.mckesson.ca"
          }
        }
      }
    }

    # Production Subscription (Prod environment)
    prod = {
      azure_subscription_id = "0d8f4db7-06d4-4f7f-9083-7827cff44449" # mck-canada-b2c-prod

      location       = "Canada Central"
      location_short = "cacentral"

      vnet = {
        # Address space
        # 10.202.14.0/23 (512 IPs)
        # 10.202.14.0 - 10.202.15.255
        resource_group_name = "rg-vnet-canadacentral-mck-canada-b2c-prod"
        name                = "vnet-canadacentral-mck-canada-b2c-prod"
      }

      subnets = {
        private_endpoints = "10.202.14.0/25" # (128 IPs) 10.202.14.0 - 10.202.14.127
      }

      # Used to assign KeyVault permissions
      object_ids = {
        sp_b2c_keyvault   = local.object_ids.sp_b2c_keyvault_as10667_prod
        sp_b2c_terraform  = local.object_ids.sp_b2c_terraform_as10667_prod
        contributor_group = local.object_ids.azure_mck_canada_b2c_prod_contributor
      }

      automation_account = {
        worker_id = "3f0efaf4-1638-4156-a871-8931695adce7"
        vm_id     = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Compute/virtualMachines/vmrbwceprd"
      }

      sub_envs = {
        preprd = {
          tenants = ["bp", "px", "up"]

          mongodb = {
            node_count                      = 3
            instance_size                   = "M10"
            cloud_region                    = "CANADA_CENTRAL"
            private_connection_resource_id  = "/subscriptions/366985d4-8eff-4d0b-8a3c-33ea5a60f6ee/resourceGroups/rg_68924cc7481d8a13022fa990_yfc9aq1p/providers/Microsoft.Network/privateLinkServices/pls_68b054bc361ae560234e2d19"
            private_service_connection_name = "pls_68b054bc361ae560234e2d19"
          }

          # With webapps going trough Impreva, not sure if custom domain are even needed !?
          web_custom_domains = {
            ask       = "" # "ask-b2c-preprd.mckesson.ca"
            tenant_bp = "" # "monfidelo-b2c-preprd.mckesson.ca"
            tenant_px = "" # "groupeproxim-app-b2c-preprd.mckesson.ca"
            tenant_up = "" # "uniprix-app-b2c-preprd.mckesson.ca"
          }

          automation_account = {
            worker_id = "037FA804-857F-4DA8-9A78-BC7A0D6B6A85"
            vm_id     = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Compute/virtualMachines/vmrbwceprd"
          }
        },
        prd = {
          tenants = ["bp", "px", "up"]

          mongodb = {
            node_count    = 3
            instance_size = "M20"
            cloud_region  = "CANADA_CENTRAL"

            private_connection_resource_id  = "/subscriptions/2a804c06-da6e-4d7b-964c-0e0a6b6f1add/resourceGroups/rg_6888dc16aab1770b5770efc9_gzepahpy/providers/Microsoft.Network/privateLinkServices/pls_6888dc16aab1770b5770efc7"
            private_service_connection_name = "pls_6888dc16aab1770b5770efc7"
          }

          # With webapps going trough Impreva, not sure if custom domain are even needed !?
          web_custom_domains = {
            ask       = "" # "ask-b2c-prd.mckesson.ca"
            tenant_bp = "" # "monfidelo-b2c-prd.mckesson.ca"
            tenant_px = "" # "groupeproxim-app-b2c-prd.mckesson.ca"
            tenant_up = "" # "uniprix-app-b2c-prd.mckesson.ca"
          }
        }
      }
    }
  }

  env_vars = local.envs[var.environment]

  # Shared DNS zones that already exist. We're just building the ID directly using this prefix
  private_dns_zones_id_prefix = "/subscriptions/0434640a-3f6c-4b39-80e2-9a279e495628/resourceGroups/rg-privatednszone/providers/Microsoft.Network/privateDnsZones/"

  object_ids = {
    # Use by AKS to retreive secrets from KeyVaults
    # https://portal.azure.com/#view/Microsoft_AAD_IAM/ManagedAppMenuBlade/~/Overview/objectId/c98740f0-2a24-409e-a326-4cc3f8b22931/appId/ae54edb8-fa8f-4a39-a28f-f5e8151a44f3
    sp_b2c_keyvault_as11574_nonprod = "c98740f0-2a24-409e-a326-4cc3f8b22931"

    # Use by AKS to retreive secrets from KeyVaults
    # https://portal.azure.com/#view/Microsoft_AAD_IAM/ManagedAppMenuBlade/~/Overview/objectId/6aeb3e3c-b090-44d2-b23f-6f7b86bdc7b8/appId/5f0d2efc-7254-4956-b7ab-90bae4211c38
    sp_b2c_keyvault_as10667_prod = "6aeb3e3c-b090-44d2-b23f-6f7b86bdc7b8"

    # Service Principal - Non-Prod - Used by Azure DevOps/GitHub Actions
    # https://portal.azure.com/#view/Microsoft_AAD_IAM/ManagedAppMenuBlade/~/Overview/objectId/17c5d60e-639a-445f-8dd4-7b8a78e31293/appId/1eec351e-7c13-4737-a97b-ab6f4b2c05a1
    sp_b2c_terraform_as11574_nonprod = "17c5d60e-639a-445f-8dd4-7b8a78e31293" # sp-b2c-terraform-as11574

    # Entra ID Group of Non-Prod Admins
    # https://portal.azure.com/#view/Microsoft_AAD_IAM/GroupDetailsMenuBlade/~/Overview/groupId/df77f60e-9dee-4744-9877-e7d10a35f608
    azure_mt_canada_b2c_nonprod_contributor = "df77f60e-9dee-4744-9877-e7d10a35f608" # azure-mt-canada-b2c-nonprod.contributor

    # Service Principal - Prod - Used by Azure DevOps/GitHub Actions
    # https://portal.azure.com/#view/Microsoft_AAD_IAM/ManagedAppMenuBlade/~/Overview/objectId/3dcfd309-4215-4f45-b077-9b8fc2dfaaa4/appId/c089bcf5-9df8-48fd-851e-3d04421730cb
    sp_b2c_terraform_as10667_prod = "3dcfd309-4215-4f45-b077-9b8fc2dfaaa4" # sp-b2c-terraform-as10667

    # Entra ID Group of Prod Admins
    # https://portal.azure.com/#view/Microsoft_AAD_IAM/GroupDetailsMenuBlade/~/Overview/groupId/0d26e82c-1fb4-461b-a35f-e8b4cd91602a
    azure_mck_canada_b2c_prod_contributor = "0d26e82c-1fb4-461b-a35f-e8b4cd91602a" # azure-mck-canada-b2c-prod.contributor
  }

  # Build map of every combination of subEnvs and tenants
  tenants = {
    for pair in flatten([
      for envName, envValues in local.env_vars.sub_envs : [
        for tenantCode in envValues.tenants : {
          key = "${envName}-${tenantCode}"
          value = {
            envName    = envName,
            tenantCode = tenantCode
          }
        }
      ]
    ]) : pair.key => pair.value
  }

  tags = {
    Note = "This resource is managed by Terraform"
  }
}

data "azurerm_client_config" "current" {
  # Contains:
  #   client_id - Azure Client ID (Application Object ID).
  #   tenant_id - Azure Tenant ID.
  #   subscription_id - Azure Subscription ID.
  #   object_id - Azure Object ID.
}

# Storage Accounts
#
# Use this command to list all storage accounts and their matching Carebook name
#   az storage account list --query "[?tags.CarebookStorageName].{ResourceGroup:resourceGroup, Name:name, CarebookStorageName:tags.CarebookStorageName}" -o table
#

module "storage_packages" {
  source = "./modules/storage"

  azure = {
    # Setup in prod's shared resource group
    resource_group_name = data.azurerm_resource_group.main.name
    location            = data.azurerm_resource_group.main.location
    tags = merge(local.tags,
      {
        CarebookStorageName = "cbpackages"
    })
  }

  name = "${local.prefix.storage}${var.environment}packages"

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }

  storage_containers = ["packages"]
}

module "storage_central_config" {
  source = "./modules/storage"

  azure = {
    # Setup in prod's shared resource group
    resource_group_name = data.azurerm_resource_group.main.name
    location            = data.azurerm_resource_group.main.location
    tags = merge(local.tags,
      {
        CarebookStorageName = "mkcentralconfig"
    })
  }

  name = "${local.prefix.storage}${var.environment}config"

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }

  storage_containers = ["bff", "dataprotection", "enterprise", "website"]
}

module "storage_files" {
  source = "./modules/storage"

  # Per env-tenant
  for_each = local.tenants

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.value.envName].name
    location            = azurerm_resource_group.sub_env[each.value.envName].location
    tags = merge(azurerm_resource_group.sub_env[each.value.envName].tags,
      {
        CarebookStorageName = "${each.value.envName == "dev" ? "cbca" : "mkca"}${each.value.envName}fileshare0${each.value.tenantCode}"
    })
  }

  name = "${local.prefix.storage}${each.value.envName}files0${each.value.tenantCode}"

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }

  file_shares = {
    files = {
      quotaGB = 10240
    }
  }
}

module "storage_survey" {
  source = "./modules/storage"

  # Per env-tenant
  for_each = local.tenants

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.value.envName].name
    location            = azurerm_resource_group.sub_env[each.value.envName].location
    tags                = azurerm_resource_group.sub_env[each.value.envName].tags
    tags = merge(azurerm_resource_group.sub_env[each.value.envName].tags,
      {
        CarebookStorageName = "${each.value.envName == "dev" ? "cbca" : "mkca"}${each.value.envName}survey0${each.value.tenantCode}"
    })
  }

  name = "${local.prefix.storage}${each.value.envName}survey0${each.value.tenantCode}"

  storage_tables = [
    "ChatSession",
    "ChatSessionIndex",
    "SurveyResponseV1"
  ]

  file_shares = each.value.tenantCode == "bp" || each.value.tenantCode == "px" ? {
    # Only for bp & px
    files = {
      quotaGB = 10240
    }
  } : {}

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}

module "storage_web_ask" {
  source = "./modules/storage"

  # Per env
  for_each = local.env_vars.sub_envs

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags = merge(azurerm_resource_group.sub_env[each.key].tags,
      {
        # cdn mkprdcaask
        CarebookStorageName = "cdn${each.key == "dev" ? "cbdev" : "mk${each.key}ca"}ask"
    })
  }

  name = "${local.prefix.storage}${each.key}webask"

  is_web = true

  custom_domain = local.env_vars.sub_envs[each.key].web_custom_domains.ask

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}

# ========================================
# DEPRECATED: Consolidated Web Storage
# ========================================
# This storage_web module is DEPRECATED and is a candidate for removal.
# It should be removed once everything is fully shifted over to the
# tenant-specific web storage accounts (storage_web_tenants module).
# ========================================
module "storage_web" {
  source = "./modules/storage"

  # Per env
  for_each = local.env_vars.sub_envs

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags = merge(azurerm_resource_group.sub_env[each.key].tags,
      {
        # cdn mkprdcaask
        CarebookStorageName = "cdn${each.key == "dev" ? "cbcadev" : "mk${each.key}ca"}"
    })
  }

  name = "${local.prefix.storage}${each.key}web"

  is_web = true

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}
# ========================================
# END DEPRECATED SECTION
# ========================================

# Tenant-specific static website storage accounts
module "storage_web_tenants" {
  source = "./modules/storage"

  for_each = local.tenants

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.value.envName].name
    location            = azurerm_resource_group.sub_env[each.value.envName].location
    tags = merge(azurerm_resource_group.sub_env[each.value.envName].tags,
      {
        # Reference the original consolidated storage account name (same as storage_web)
        CarebookStorageName = "cdn${each.value.envName == "dev" ? "cbcadev" : "mk${each.value.envName}ca"}"
    })
  }

  name = "${local.prefix.storage}${each.value.envName}${each.value.tenantCode}web"

  is_web = true

  custom_domain = local.env_vars.sub_envs[each.value.envName].web_custom_domains["tenant_${each.value.tenantCode}"]

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}

module "storage_reports" {
  source = "./modules/storage"

  # Per env
  for_each = local.env_vars.sub_envs

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags = merge(azurerm_resource_group.sub_env[each.key].tags,
      {
        # cdn mkprdcaask
        CarebookStorageName = "cbca${each.key}${each.key == "dev" ? "" : "mk"}reports"
    })
  }

  name = "${local.prefix.storage}${each.key}reports"

  is_hns_enabled                = true
  is_sftp_enabled               = true
  public_network_access_enabled = each.key == "prd"

  private_endpoint = each.key == "prd" ? null : {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}

module "storage_secevents" {
  source = "./modules/storage"

  # Per env
  for_each = local.env_vars.sub_envs

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags = merge(azurerm_resource_group.sub_env[each.key].tags,
      {
        # cdn mkprdcaask
        CarebookStorageName = "${each.key == "dev" ? "cbcadev" : "mkca${each.key}"}securityevents"
    })
  }

  name = "${local.prefix.storage}${each.key}secevents"

  storage_tables = [
    "alertEntries"
  ]

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}

# Potential canidates for storage accounts:
# - sftp              but only for prd and uat ?

# Dev-only tenant-specific dynamic links storage accounts
module "storage_dynamiclinks_tenants" {
  source = "./modules/storage"

  # NOTE: Restricted to prod environments because a single instance
  # that manages the dynamic links for all environments is how Carebook does it.
  for_each = {
    for key, value in local.tenants : key => value
    if value.envName == "prd" && value.tenantCode != "bp"
  }

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.value.envName].name
    location            = azurerm_resource_group.sub_env[each.value.envName].location
    tags = merge(azurerm_resource_group.sub_env[each.value.envName].tags,
      {
        # Reference the original consolidated storage account name
        CarebookStorageName = "dynamiclinksdev${each.value.envName}"
    })
  }

  name = "${local.prefix.storage}${each.value.envName}dynlinks${each.value.tenantCode}"

  is_web = true

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}

module "storage_fhir_migration_state" {
  source = "./modules/storage"

  # Per env
  for_each = local.env_vars.sub_envs

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags = merge(azurerm_resource_group.sub_env[each.key].tags,
      {
        # originally Carebook used the same one for all environments
        CarebookStorageName = "mkfhirmigrationstate"
    })
  }

  name = "${local.prefix.storage}${each.key}fhirstate"

  storage_tables = [
    "Mk${each.key}Ca"
  ]

  no_blob_private_endpoint = true # There are no blobs in this storage account

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}

module "storage_loyalty" {
  source = "./modules/storage"

  for_each = local.env_vars.sub_envs

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags = merge(azurerm_resource_group.sub_env[each.key].tags,
      {
        LoyaltyStorageName = "Loyalty-${each.key}"
    })
  }

  name = "${local.prefix.storage}${each.key}loyalty"

  storage_containers = ["ios"]

  is_web = false

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}
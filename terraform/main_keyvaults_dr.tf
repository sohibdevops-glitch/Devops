# ============================================================
# Key Vault DR - Canada East
# 5 secondary vaults in rg-rbg-b2c-winterfell-dr (confirmed by
# Kevin, created and verified Succeeded on 2026-11-02)
# ============================================================

# --------------------------------------------------------------
# New regional private DNS zone for Key Vault in Canada East.
# Same pattern as blob_caeast for storage - one zone per region,
# linked only to its own VNet (per the DR plan's own rule).
# --------------------------------------------------------------
resource "azurerm_private_dns_zone" "vault_caeast" {
  count = var.environment == "prod" ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
}

resource "azurerm_private_dns_zone_virtual_network_link" "vault_caeast_link" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = "link-vault-caeast"
  resource_group_name   = "rg-vnet-canadaeast-mck-canada-b2c"
  private_dns_zone_name = azurerm_private_dns_zone.vault_caeast[0].name
  virtual_network_id    = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-vnet-canadaeast-mck-canada-b2c/providers/Microsoft.Network/virtualNetworks/vnet-canadaeast-mck-canada-b2c"
}

locals {
  # Prefix used by the keyvault module's private_endpoint config -
  # same mechanism as local.private_dns_zones_id_prefix, just
  # pointed at the new Canada East zone instead of the shared one.
  vault_caeast_dns_zone_id_prefix = var.environment == "prod" ? trimsuffix(azurerm_private_dns_zone.vault_caeast[0].id, azurerm_private_dns_zone.vault_caeast[0].name) : null
}

# --------------------------------------------------------------
# 5 Canada East vaults - same permission pattern as their
# Canada Central counterparts in main_keyvaults.tf
# --------------------------------------------------------------

module "key_vault_bp_dr" {
  source = "./modules/keyvault"
  count  = var.environment == "prod" ? 1 : 0

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = "rg-rbg-b2c-winterfell-dr"
    location            = "Canada East"
    tags                = local.tags
  }

  name = "${local.prefix.keyvault}-prd-bp-dr"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = local.caeast_subnet_id
    dns_zone_id_prefix = local.vault_caeast_dns_zone_id_prefix
  }

  permissions = {
    sp_b2c_keyvault = {
      object_id   = local.env_vars.object_ids.sp_b2c_keyvault
      get_secrets = true
    }
    sp_b2c_terraform = {
      object_id      = local.env_vars.object_ids.sp_b2c_terraform
      manage_secrets = true
    }
    contributor_group = {
      object_id      = local.env_vars.object_ids.contributor_group
      manage_secrets = true
    }
  }
}

module "key_vault_px_dr" {
  source = "./modules/keyvault"
  count  = var.environment == "prod" ? 1 : 0

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = "rg-rbg-b2c-winterfell-dr"
    location            = "Canada East"
    tags                = local.tags
  }

  name = "${local.prefix.keyvault}-prd-px-dr"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = local.caeast_subnet_id
    dns_zone_id_prefix = local.vault_caeast_dns_zone_id_prefix
  }

  permissions = {
    sp_b2c_keyvault = {
      object_id   = local.env_vars.object_ids.sp_b2c_keyvault
      get_secrets = true
    }
    sp_b2c_terraform = {
      object_id      = local.env_vars.object_ids.sp_b2c_terraform
      manage_secrets = true
    }
    contributor_group = {
      object_id      = local.env_vars.object_ids.contributor_group
      manage_secrets = true
    }
  }
}

module "key_vault_up_dr" {
  source = "./modules/keyvault"
  count  = var.environment == "prod" ? 1 : 0

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = "rg-rbg-b2c-winterfell-dr"
    location            = "Canada East"
    tags                = local.tags
  }

  name = "${local.prefix.keyvault}-prd-up-dr"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = local.caeast_subnet_id
    dns_zone_id_prefix = local.vault_caeast_dns_zone_id_prefix
  }

  permissions = {
    sp_b2c_keyvault = {
      object_id   = local.env_vars.object_ids.sp_b2c_keyvault
      get_secrets = true
    }
    sp_b2c_terraform = {
      object_id      = local.env_vars.object_ids.sp_b2c_terraform
      manage_secrets = true
    }
    contributor_group = {
      object_id      = local.env_vars.object_ids.contributor_group
      manage_secrets = true
    }
  }
}

# mk - special case: holds the IdentityService dataprotection key,
# needs use_keys/manage_keys in addition to the standard permissions
module "key_vault_mk_dr" {
  source = "./modules/keyvault"
  count  = var.environment == "prod" ? 1 : 0

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = "rg-rbg-b2c-winterfell-dr"
    location            = "Canada East"
    tags                = local.tags
  }

  name = "${local.prefix.keyvault}-prd-mk-dr"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = local.caeast_subnet_id
    dns_zone_id_prefix = local.vault_caeast_dns_zone_id_prefix
  }

  permissions = {
    sp_b2c_keyvault = {
      object_id   = local.env_vars.object_ids.sp_b2c_keyvault
      get_secrets = true
      use_keys    = true
    }
    sp_b2c_terraform = {
      object_id      = local.env_vars.object_ids.sp_b2c_terraform
      manage_secrets = true
      manage_keys    = true
    }
    contributor_group = {
      object_id      = local.env_vars.object_ids.contributor_group
      manage_secrets = true
      manage_keys    = true
    }
  }
}

# devops - restricted: pipeline + admins only, no app access
module "key_vault_devops_dr" {
  source = "./modules/keyvault"
  count  = var.environment == "prod" ? 1 : 0

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = "rg-rbg-b2c-winterfell-dr"
    location            = "Canada East"
    tags                = local.tags
  }

  name = "${local.prefix.keyvault}-prd-devops-dr"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = local.caeast_subnet_id
    dns_zone_id_prefix = local.vault_caeast_dns_zone_id_prefix
  }

  permissions = {
    sp_b2c_terraform = {
      object_id      = local.env_vars.object_ids.sp_b2c_terraform
      manage_secrets = true
    }
    contributor_group = {
      object_id      = local.env_vars.object_ids.contributor_group
      manage_secrets = true
    }
  }
}

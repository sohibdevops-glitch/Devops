# Key Vault
module "key_vault_global" {
  source = "./modules/keyvault"

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = data.azurerm_resource_group.main.name
    location            = data.azurerm_resource_group.main.location
    tags                = local.tags
  }

  # Global KeyVault, mainly used for certificates
  name = "${local.prefix.keyvault}-${var.environment}"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }

  # TODO: Add certificates in this vault

  permissions = {
    sp_b2c_keyvault = {
      object_id        = local.env_vars.object_ids.sp_b2c_keyvault
      get_secrets      = true
      use_keys         = true
      use_certificates = true
    }
    sp_b2c_terraform = {
      object_id           = local.env_vars.object_ids.sp_b2c_terraform
      manage_secrets      = true
      manage_keys         = true
      manage_certificates = true
    }
    contributor_group = {
      object_id           = local.env_vars.object_ids.contributor_group
      manage_secrets      = true
      manage_keys         = true
      manage_certificates = true
    }
  }
}

module "key_vault_devops" {
  source = "./modules/keyvault"

  for_each = local.env_vars.sub_envs

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags                = local.tags
  }

  # For Azure DevOps pipeline variables/secrets
  name = "${local.prefix.keyvault}-${each.key}-devops"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
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

module "key_vault_px" {
  source = "./modules/keyvault"

  for_each = local.env_vars.sub_envs

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags                = local.tags
  }

  name = "${local.prefix.keyvault}-${each.key}-px"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
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

module "key_vault_up" {
  source = "./modules/keyvault"

  for_each = local.env_vars.sub_envs

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags                = local.tags
  }

  name = "${local.prefix.keyvault}-${each.key}-up"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
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

module "key_vault_bp" {
  source = "./modules/keyvault"

  for_each = local.env_vars.sub_envs

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags                = local.tags
  }

  name = "${local.prefix.keyvault}-${each.key}-bp"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
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

# Tenant 'mk' is used as fallback/default KeyVault
module "key_vault_mk" {
  source = "./modules/keyvault"

  for_each = local.env_vars.sub_envs

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags                = local.tags
  }

  name = "${local.prefix.keyvault}-${each.key}-mk"
  sku  = "standard"

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }

  # This vault contains special 'dataprotection' key used by IdentityService for encryption/decryption.

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

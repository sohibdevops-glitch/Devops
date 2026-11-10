data "azurerm_client_config" "current" {
  # Contains:
  #   client_id - Azure Client ID (Application Object ID).
  #   tenant_id - Azure Tenant ID.
  #   subscription_id - Azure Subscription ID.
  #   object_id - Azure Object ID.
}

# AppConfig resource
data "azurerm_app_configuration" "app_config" {
  resource_group_name = local.resource_group_name

  name = "ac-${local.prefix.generic}-${local.subEnv}"
}

# AppConfig Keys in Azure, to find untracked app config keys
data "azurerm_app_configuration_keys" "remote_keys" {
  configuration_store_id = data.azurerm_app_configuration.app_config.id
}

# Per Tenant Key Vault
data "azurerm_key_vault" "tenant" {
  for_each = toset(local.env_vars.sub_envs[local.subEnv].tenants)

  resource_group_name = local.resource_group_name

  name = "${local.prefix.keyvault}-${local.subEnv}-${each.key}"
}

# MK Key Vault (for dataprotection key and ConfigurationJson)
data "azurerm_key_vault" "mk" {
  resource_group_name = local.resource_group_name

  name = "${local.prefix.keyvault}-${local.subEnv}-mk"
}

# DevOps Key Vault
data "azurerm_key_vault" "devops" {
  resource_group_name = local.resource_group_name

  name = "${local.prefix.keyvault}-${local.subEnv}-devops"
}

# Message Bus
data "azurerm_servicebus_namespace" "sbus" {
  resource_group_name = local.resource_group_name

  name = "sb-${local.prefix.generic}-${local.subEnv}"
}

# Security Event Storage
data "azurerm_storage_account" "secevents" {
  resource_group_name = local.resource_group_name

  name = "${local.prefix.storage}${local.subEnv}secevents"
}

# fhir migration state storage
data "azurerm_storage_account" "fhir_migration_state" {
  resource_group_name = local.resource_group_name

  name = "${local.prefix.storage}${local.subEnv}fhirstate"
}

# Data Factory
data "azurerm_data_factory" "adf" {
  resource_group_name = local.resource_group_name

  name = "adf-${local.prefix.generic}-${local.subEnv}"
}


# Get Firestore private_key from vault
data "azurerm_key_vault_secret" "firestore_private_key" {

  for_each = {
    for pair in flatten([
      for tenantCode in local.tenants : [
        # For DEV only !!
        for secretName in local.subEnv == "dev" ? [
          "CommunicationService:Firestore:private_key",
          "IdentityService:Firestore:private_key",
          ] : [] : {
          # Use this key when getting secret value for AppConfig
          key = "${tenantCode}-${secretName}"
          value = {
            secretName = secretName
            tenantCode = tenantCode
          }
        }
      ]
    ]) : pair.key => pair.value
  }

  name = replace(replace(each.value.secretName, ":", "--"), "_", "----")

  # Use tenant specific vault
  key_vault_id = data.azurerm_key_vault.tenant[each.value.tenantCode].id
}


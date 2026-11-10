locals {
  # Load AppConfigs from file
  app_configs = yamldecode(file("${path.module}/appConfigs/${local.subEnv}.yml"))

  # Load firestore configs for each tenant
  firestore_configs = {
    for tenant in local.tenants : tenant => jsondecode(file("${path.module}/firestoreConfigs/${tenant}.json")) # At the moment config is the same for all environments
  }

  # Merge all values into a single map object. Values merged later override previous values
  merged_app_configuration = merge(

    # Values from file
    local.app_configs,

    # Items below should override any "<<DEFINED BY TERRAFORM>>" set in the config file

    merge([
      # Per Tenant Configs
      for tenant in local.tenants : merge({
        "tenant:${tenant}:AskService:Firestore:BaseAddress" = "https://firestore.googleapis.com/v1/projects/${local.firestore_configs[tenant].project_id}/databases/(default)/documents/"
        }, merge([
          # Generate the same config for these services
          for serviceName in ["CommunicationService", "IdentityService"] : {
            "tenant:${tenant}:${serviceName}:Firestore:auth_provider_x509_cert_url" = local.firestore_configs[tenant].auth_provider_x509_cert_url
            "tenant:${tenant}:${serviceName}:Firestore:auth_uri"                    = local.firestore_configs[tenant].auth_uri
            "tenant:${tenant}:${serviceName}:Firestore:client_email"                = local.firestore_configs[tenant].client_email
            "tenant:${tenant}:${serviceName}:Firestore:client_id"                   = local.firestore_configs[tenant].client_id
            "tenant:${tenant}:${serviceName}:Firestore:client_x509_cert_url"        = local.firestore_configs[tenant].client_x509_cert_url
            "tenant:${tenant}:${serviceName}:Firestore:private_key"                 = local.firestore_configs[tenant].private_key
            "tenant:${tenant}:${serviceName}:Firestore:private_key_id"              = local.firestore_configs[tenant].private_key_id
            "tenant:${tenant}:${serviceName}:Firestore:project_id"                  = local.firestore_configs[tenant].project_id
            "tenant:${tenant}:${serviceName}:Firestore:token_uri"                   = local.firestore_configs[tenant].token_uri
            "tenant:${tenant}:${serviceName}:Firestore:type"                        = local.firestore_configs[tenant].type
          }
        ]...)
    )]...),

    # Environment specific configs that Terraform can assign with the right values
    {
      "Reporting:DataFactoryConfiguration:AzureSubscriptionId" = local.env_vars.azure_subscription_id
      "Reporting:DataFactoryConfiguration:AzureTenantId"       = local.tenant_id
      "Reporting:DataFactoryConfiguration:Name"                = data.azurerm_data_factory.adf.name
      "Reporting:DataFactoryConfiguration:ResourceGroup"       = data.azurerm_data_factory.adf.resource_group_name
      "SecurityLogging:StorageConnectionString"                = data.azurerm_storage_account.secevents.primary_connection_string
    },

    # WORKAROUND: In dev write these secrets directly to AppConfig.
    #             They are already set in KeyVault and should be read from there...
    #             But it looks like dev isn't always reading from Vault
    local.subEnv == "dev" ? {
      "tenant:px:CommunicationService:Firestore:private_key" = data.azurerm_key_vault_secret.firestore_private_key["px-CommunicationService:Firestore:private_key"]
      "tenant:px:IdentityService:Firestore:private_key"      = data.azurerm_key_vault_secret.firestore_private_key["px-IdentityService:Firestore:private_key"]
      "tenant:up:CommunicationService:Firestore:private_key" = data.azurerm_key_vault_secret.firestore_private_key["up-CommunicationService:Firestore:private_key"]
      "tenant:up:IdentityService:Firestore:private_key"      = data.azurerm_key_vault_secret.firestore_private_key["up-IdentityService:Firestore:private_key"]
    } : {},

    # WORKAROUND: In dev write these secrets directly to AppConfig.
    #             If we don't want the secrets values in AppConfig, they need to go into the secret 'ConfigurationJson' in the '-mk' KeyVault.
    local.subEnv == "dev" ? {
      "HealthService:FhirMigrator:Store:ConnectionString" = data.azurerm_storage_account.fhir_migration_state.primary_connection_string

      "CalculationService:ServiceBusSettings:ConnectionString"     = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "CommunicationService:ServiceBusSettings:ConnectionString"   = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "DocumentStoreService:ServiceBusSettings:ConnectionString"   = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "ESiService:ServiceBusSettings:ConnectionString"             = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "HealthService:ServiceBusSettings:ConnectionString"          = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "IdentityService:ServiceBusSettings:ConnectionString"        = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "LinkManagerService:ServiceBusSettings:ConnectionString"     = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "LoyaltyService:ServiceBusSettings:ConnectionString"         = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "ProfileService:ServiceBusSettings:ConnectionString"         = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "ProximPharmacyService:ServiceBusSettings:ConnectionString"  = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "RexallPharmacyService:ServiceBusSettings:ConnectionString"  = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "StoreService:ServiceBusSettings:ConnectionString"           = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "SurveyClientService:ServiceBusSettings:ConnectionString"    = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "SurveyService:ServiceBusSettings:ConnectionString"          = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "UniprixPharmacyService:ServiceBusSettings:ConnectionString" = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
      "ReminderService:ServiceBusSettings:ConnectionString"        = data.azurerm_servicebus_namespace.sbus.default_primary_connection_string
    } : {},


    # Per Env Secrets values that need to be in AppConfig and defined in `main_secrets.tf`
    { for secret in azurerm_key_vault_secret.app_config_secret_per_env : secret.tags.AppConfigKey => secret.value },

    # Per Tenant Secrets that need to be in AppConfig and defined in `main_secrets.tf`
    { for secret in azurerm_key_vault_secret.app_config_secret_per_tenant : secret.tags.AppConfigKey => secret.value }
  )
}

# AppConfig Values
resource "azurerm_app_configuration_key" "config" {
  for_each = local.merged_app_configuration

  configuration_store_id = data.azurerm_app_configuration.app_config.id

  key          = each.key
  value        = jsonencode(each.value)
  content_type = "application/json"
}

# Write untracked AppConfig keys to file
resource "local_file" "untracked_app_configs" {
  content = yamlencode(
    # Compare local config keys with remote keys (in AppConfig)
    # List keys that don't exist locally; not tracked by Terraform
    setsubtract(
      toset([for item in data.azurerm_app_configuration_keys.remote_keys.items : item.key]),
    toset(keys(local.merged_app_configuration)))
  )
  filename = "${path.module}/untrackedAppConfigs/${local.subEnv}.yml"
}

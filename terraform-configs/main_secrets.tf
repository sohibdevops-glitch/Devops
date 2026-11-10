# Some secrets must be set in AppConfig because the services don’t always read from KeyVault.
# To keep secrets out of Terraform code and source control we:
#   - let Terraform create a placeholder secret in KeyVault
#   - manually set the correct secret value in KeyVault
#   - let Terraform read the secret and set the value in AppConfig
# Long term solution is to update the service code to always read from KeyVault and not have secrets in AppConfig.

locals {

  # Per Environment
  appConfigSecretsPerEnv = [
    "Loggly:InputKey",

    # TODO: Requires a secret to contain the value and set in AppConfig
    #"HealthService:FhirMigrator:Store:ConnectionString"

    # TODO: See if this is need or can be loaded directly from KeyVault
    # "LoyaltyService:ExchangeSolution:Authentication:OcpApimSubscriptionKey:MK"
  ]

  # Per Tenant
  appConfigSecretsPerTenant = [
    "AskService:AirTable:ApiKey",
    "CommunicationService:SalesForceSettings:OAuthClientSecret",
    "CommunicationService:SendGridSettings:Password"
  ]
}

# These secrets are created in the "devops" KeyVault
resource "azurerm_key_vault_secret" "app_config_secret_per_env" {
  for_each = toset(local.appConfigSecretsPerEnv)

  # Name can't have : so we change to --
  name = replace(each.value, ":", "--")

  value = "TODO" # Untracked placeholder for creating the secret the first time

  expiration_date = "2099-01-01T00:00:00Z"

  # Use per env. KeyVault
  key_vault_id = data.azurerm_key_vault.devops.id

  tags = {
    # Used to assign secret value into AppConfig
    AppConfigKey = each.value
  }

  lifecycle {
    ignore_changes = [
      value,
      expiration_date
    ]
  }
}

# These secrets are created in the "-tenant" KeyVaults
resource "azurerm_key_vault_secret" "app_config_secret_per_tenant" {
  # Combine secrets, env, and tenants
  for_each = {
    for pair in flatten([
      for tenantCode in local.tenants : [
        for secretName in local.appConfigSecretsPerTenant : {
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

  # Name can't have : so we change to --
  name = replace(each.value.secretName, ":", "--")

  value = "TODO" # Untracked placeholder for creating the secret the first time

  expiration_date = "2099-01-01T00:00:00Z"

  # Use tenant specific vault
  key_vault_id = data.azurerm_key_vault.tenant[each.value.tenantCode].id

  tags = {
    # Used to assign secret value into AppConfig
    AppConfigKey = "tenant:${each.value.tenantCode}:${each.value.secretName}"
  }

  lifecycle {
    ignore_changes = [
      value,
      expiration_date
    ]
  }
}

# Generate ConfigurationJson secret
resource "azurerm_key_vault_secret" "configuration_json" {

  # Set in fallback tenant key vault
  key_vault_id = data.azurerm_key_vault.mk.id

  name = "ConfigurationJson"

  # Value is too complex and must be managed manually
  value = "Define json secrets here"

  expiration_date = "2099-01-01T00:00:00Z"

  lifecycle {
    ignore_changes = [value, expiration_date, tags]
  }
}

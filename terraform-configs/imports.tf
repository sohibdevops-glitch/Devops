# Import existing production Key Vault secrets into Terraform state.

import {
 to = azurerm_key_vault_secret.app_config_secret_per_tenant["bp-AskService:AirTable:ApiKey"]
 id = "https://kv-rbg-b2c-prd-bp.vault.azure.net/secrets/AskService--AirTable--ApiKey/e18d9d1272b0409e94e3f0e701b63db3"
}
import {
 to = azurerm_key_vault_secret.app_config_secret_per_tenant["bp-CommunicationService:SalesForceSettings:OAuthClientSecret"]
 id = "https://kv-rbg-b2c-prd-bp.vault.azure.net/secrets/CommunicationService--SalesForceSettings--OAuthClientSecret/06d588a791264d2a9d77eef43b4a402d"
}
import {
 to = azurerm_key_vault_secret.app_config_secret_per_tenant["bp-CommunicationService:SendGridSettings:Password"]
 id = "https://kv-rbg-b2c-prd-bp.vault.azure.net/secrets/CommunicationService--SendGridSettings--Password/51483ec74faa4d93a2b2d454ac0d706b"
}

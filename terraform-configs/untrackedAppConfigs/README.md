# Untracked App Configs

Files in this folder show configuration keys that exist in Azure's App Config but NOT in Terraform.

All configurations should exist in Terraform so changes can be tracked correctly.


## How to add existing AppConfig Key/Value


1. Add an entry `Key = Value` in the corresponding environment file in `terraform-local/appConfigs/xxx.yml`

2. Import the existing Azure entry into Terraform's state:
   ```
   # Example importing key 'IdentityService:AllowedCorsOrigins:CarebookWeb:10'
   terraform import 'azurerm_app_configuration_key.config["IdentityService:AllowedCorsOrigins:CarebookWeb:10"]' "https://ac-rbg-b2c-winterfell-caeast-dev.azconfig.io/kv/IdentityService:AllowedCorsOrigins:CarebookWeb:10?label="
   ```


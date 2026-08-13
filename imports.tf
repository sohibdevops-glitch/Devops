locals {
 existing_app_configuration_keys = {
   "IdentityService:ClientsCredentials:MyVitalsForWorkMobile" = "IdentityService:ClientsCredentials:MyVitalsForWorkMobile"
   "RexallPharmacyService:Version:Deprecated"                  = "RexallPharmacyService:Version:Deprecated"
 }
}
import {
 for_each = local.existing_app_configuration_keys
 to = azurerm_app_configuration_key.config[each.key]
 id = "https://ac-rbg-b2c-winterfell-cacentral-prd.azconfig.io/kv/${each.value}?label="
}

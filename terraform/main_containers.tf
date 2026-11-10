# Azure Container Registry
module "acr" {
  source = "./modules/acr"

  azure = {
    resource_group_name = data.azurerm_resource_group.main.name
    location            = data.azurerm_resource_group.main.location
    tags                = local.tags
  }

  name = "acr${local.prefix.generic}-${var.environment}"

  # The pipelines are using user/password to authenticate
  # Eventually it would be better to use a managed identity to access ACR instead of user/pass
  admin_enabled = true

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}

# ⚠️ Since we don't have the rights to manage roles,
#     an administrator needs to manually create these assingments:
#
# Non-Prod
#   Resource: acrrbgb2cwinterfellcaeastnonprod  - https://portal.azure.com/#@mckessoncorp.onmicrosoft.com/resource/subscriptions/0e214175-4bcd-4aad-9f6e-6c02fb1f277a/resourceGroups/rg-rbg-b2c-winterfell-nonprod/providers/Microsoft.ContainerRegistry/registries/acrrbgb2cwinterfellcaeastnonprod/overview
#   Add assignment for role: AcrPull
#   To:
#     aks-b2c-canadaeast-dev-agentpool
#     aks-b2c-canadaeast-uat-agentpool
#     azure-mt-canada-b2c-nonprod.contributor
#   Add assignment for role: AcrPush
#   To:
#     azure-mt-canada-b2c-nonprod.contributor

# Prod
#   Resource: acrrbgb2cwinterfellcacentralprod - https://portal.azure.com/#@mckessoncorp.onmicrosoft.com/resource/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prod-shared/providers/Microsoft.ContainerRegistry/registries/acrrbgb2cwinterfellcacentralprod/overview
#
#   Add assignment for role: AcrPull
#   To:
#     aks-b2c-canadacentral-preprod-agentpool
#     aks-b2c-canadacentral-prod-agentpool
#     azure-mck-canada-b2c-prod.contributor
#
#   Add assignment for role: AcrPush
#   To:
#   azure-mck-canada-b2c-prod.contributor
#

resource "azurerm_subnet" "sb_private_endpoints_caeast" {
  count                = var.environment == "prod" ? 1 : 0
  name                 = "sb-private-endpoints"
  resource_group_name  = "rg-vnet-canadaeast-mck-canada-b2c"
  virtual_network_name = "vnet-canadaeast-mck-canada-b2c"
  address_prefixes     = ["10.200.13.64/26"]
}

locals {
  caeast_subnet_id = var.environment == "prod" ? azurerm_subnet.sb_private_endpoints_caeast[0].id : null
}
resource "azurerm_private_dns_zone" "blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_caeast_link" {
  count                 = var.environment == "prod" ? 1 : 0
  name                  = "link-blob-caeast"
  resource_group_name   = "rg-vnet-canadaeast-mck-canada-b2c"
  private_dns_zone_name = azurerm_private_dns_zone.blob_caeast[0].name
  virtual_network_id    = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-vnet-canadaeast-mck-canada-b2c/providers/Microsoft.Network/virtualNetworks/vnet-canadaeast-mck-canada-b2c"
}
resource "azurerm_private_endpoint" "bp_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdbpweb-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-bp-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdbpweb"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "bp_web_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdbpweb-web-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-bp-web"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdbpweb"
    subresource_names              = ["web"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "up_web_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdupweb-web-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-up-web"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdupweb"
    subresource_names              = ["web"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "px_web_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdpxweb-web-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-px-web"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdpxweb"
    subresource_names              = ["web"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "ask_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdwebask-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-ask-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdwebask"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "dynlinkspx_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprddynlinkspx-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-dynlinkspx-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprddynlinkspx"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "dynlinksup_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprddynlinksup-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-dynlinksup-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprddynlinksup"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "packages_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprodpackages-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-packages-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prod-shared/providers/Microsoft.Storage/storageAccounts/sarbgb2cprodpackages"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "config_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprodconfig-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-config-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prod-shared/providers/Microsoft.Storage/storageAccounts/sarbgb2cprodconfig"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "filesbp_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdfiles0bp-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-filesbp-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdfiles0bp"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "filespx_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdfiles0px-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-filespx-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdfiles0px"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "filesup_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdfiles0up-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-filesup-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdfiles0up"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "surveybp_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdsurvey0bp-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-surveybp-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdsurvey0bp"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "surveypx_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdsurvey0px-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-surveypx-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdsurvey0px"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "surveyup_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdsurvey0up-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-surveyup-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdsurvey0up"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "secevents_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdsecevents-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-secevents-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdsecevents"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}

resource "azurerm_private_endpoint" "px_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdpxweb-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-px-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdpxweb"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "up_blob_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdupweb-blob-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-up-blob"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdupweb"
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "ask_web_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprdwebask-web-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-ask-web"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprdwebask"
    subresource_names              = ["web"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "dynlinkspx_web_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprddynlinkspx-web-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-dynlinkspx-web"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprddynlinkspx"
    subresource_names              = ["web"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
resource "azurerm_private_endpoint" "dynlinksup_web_caeast" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "sarbgb2cprddynlinksup-web-endpoint-caeast"
  location            = "canadaeast"
  resource_group_name = "rg-vnet-canadaeast-mck-canada-b2c"
  subnet_id           = local.caeast_subnet_id
  private_service_connection {
    name                           = "psc-dynlinksup-web"
    private_connection_resource_id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd/providers/Microsoft.Storage/storageAccounts/sarbgb2cprddynlinksup"
    subresource_names              = ["web"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_caeast[0].id]
  }
}
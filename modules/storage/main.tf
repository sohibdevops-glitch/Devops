resource "azurerm_storage_account" "main" {
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  name = lower(replace(var.name, "/[^[:alnum:]]/", "")) # can only consist of lowercase letters and numbers

  account_tier                     = "Standard"
  access_tier                      = "Hot"
  account_replication_type         = var.config.account_replication_type
  cross_tenant_replication_enabled = var.config.cross_tenant_replication_enabled

  min_tls_version = "TLS1_2"

  is_hns_enabled = var.is_hns_enabled

  sftp_enabled = var.is_sftp_enabled
  
  public_network_access_enabled   = var.public_network_access_enabled
  allow_nested_items_to_be_public = false

  dynamic "custom_domain" {
    # Set when not empty
    for_each = var.custom_domain == "" ? [] : [{}]
    content {
      name          = var.custom_domain
      use_subdomain = false
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_storage_container" "main" {
  for_each = var.storage_containers

  name                  = each.key
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

resource "azurerm_storage_table" "main" {
  for_each = var.storage_tables

  name = each.key

  storage_account_name = azurerm_storage_account.main.name

  depends_on = [azurerm_private_endpoint.table] # Must have private endpoint
}

resource "azurerm_storage_share" "main" {
  for_each = var.file_shares

  name = each.key

  storage_account_id = azurerm_storage_account.main.id

  quota       = each.value.quotaGB
  access_tier = each.value.access_tier

  depends_on = [azurerm_private_endpoint.file] # Must have private endpoint
}

resource "azurerm_storage_account_static_website" "main" {
  storage_account_id = azurerm_storage_account.main.id

  index_document     = "index.html"
  error_404_document = "index.html"

  count = var.is_web ? 1 : 0
}

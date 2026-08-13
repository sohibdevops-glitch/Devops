# Private Endpoint for Blobs
resource "azurerm_private_endpoint" "blob" {
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  name = "${var.name}-blob-endpoint"

  subnet_id = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "${var.name}-blob-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "privatelink.blob.core.windows.net"
    private_dns_zone_ids = ["${var.private_endpoint.dns_zone_id_prefix}privatelink.blob.core.windows.net"]
  }

  lifecycle {
    ignore_changes = [tags]
  }

  count = var.private_endpoint == null || var.no_blob_private_endpoint ? 0 : 1
}

# Private Endpoint for Tables
resource "azurerm_private_endpoint" "table" {
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  name = "${var.name}-table-endpoint"

  subnet_id = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "${var.name}-table-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["table"]
  }

  private_dns_zone_group {
    name                 = "global-shared-dns"
    private_dns_zone_ids = ["${var.private_endpoint.dns_zone_id_prefix}privatelink.table.core.windows.net"]
  }

  lifecycle {
    ignore_changes = [tags]
  }

  # Do not create when no private endpoint config or no storage tables
  count = var.private_endpoint == null || length(var.storage_tables) == 0 ? 0 : 1
}

# Private Endpoint for Files
resource "azurerm_private_endpoint" "file" {
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  name = "${var.name}-file-endpoint"

  subnet_id = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "${var.name}-file-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "global-shared-dns"
    private_dns_zone_ids = ["${var.private_endpoint.dns_zone_id_prefix}privatelink.file.core.windows.net"]
  }

  lifecycle {
    ignore_changes = [tags]
  }

  # Do not create when no private endpoint config or no file shares
  count = var.private_endpoint == null || length(var.file_shares) == 0 ? 0 : 1
}

# Private Endpoint for Web
resource "azurerm_private_endpoint" "web" {
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  name = "${var.name}-web-endpoint"

  subnet_id = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "${var.name}-web-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["web"]
  }

  private_dns_zone_group {
    name                 = "global-shared-dns"
    private_dns_zone_ids = ["${var.private_endpoint.dns_zone_id_prefix}privatelink.web.core.windows.net"]
  }

  lifecycle {
    ignore_changes = [tags]
  }

  # Do not create when no endpoint config or no static websites
  count = var.private_endpoint == null || !(var.is_web) ? 0 : 1
}

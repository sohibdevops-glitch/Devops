resource "azurerm_storage_account" "terraform" {
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = local.tags

  name = local.tfstate_storage_account_name

  account_tier             = "Standard"
  access_tier              = "Hot"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  lifecycle {
    ignore_changes  = [tags]
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  storage_account_id = azurerm_storage_account.terraform.id

  name = "tfstate"

  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_private_endpoint" "tfstate" {
  location            = azurerm_storage_account.terraform.location
  resource_group_name = azurerm_storage_account.terraform.resource_group_name
  tags                = azurerm_storage_account.terraform.tags

  name = "${azurerm_storage_account.terraform.name}-blob-endpoint"

  subnet_id = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${azurerm_storage_account.terraform.name}-blob-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.terraform.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "privatelink.blob.core.windows.net"
    private_dns_zone_ids = ["${local.private_dns_zones_id_prefix}privatelink.blob.core.windows.net"]
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

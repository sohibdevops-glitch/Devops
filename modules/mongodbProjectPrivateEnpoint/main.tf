resource "azurerm_private_endpoint" "mongodb_private_endpoint" {
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  name = var.private_endpoint.pep_name

  subnet_id = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = var.private_endpoint.private_service_connection_name
    is_manual_connection           = true
    private_connection_resource_id = var.private_endpoint.private_connection_resource_id
    request_message                = local.request_message
  }

  lifecycle {
    ignore_changes = [tags]
  }

  count = var.private_endpoint.private_connection_resource_id == null ? 0 : 1 # Only create when defined
}

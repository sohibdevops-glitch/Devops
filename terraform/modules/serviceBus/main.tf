resource "azurerm_servicebus_namespace" "servicebus_namespace" {
  name                = var.name
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  sku = "Premium" # Premium is requered for private endpoints

  capacity                     = var.capacity
  premium_messaging_partitions = var.premium_messaging_partitions

  public_network_access_enabled = false

  lifecycle {
    ignore_changes = [tags]
  }
}

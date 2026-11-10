resource "azurerm_app_configuration" "appconfig" {
  name                = var.name
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags
  sku                 = var.sku

  public_network_access = "Disabled"

  lifecycle {
    ignore_changes = [tags]
  }
}

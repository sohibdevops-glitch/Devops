resource "azurerm_app_configuration_key" "config" {
  for_each               = var.app_config_key_value
  configuration_store_id = azurerm_app_configuration.appconfig.id

  key   = each.key
  value = jsonencode(each.value)
  content_type = "application/json"

  depends_on = [azurerm_private_endpoint.appconfig] # Must have private endpoint
}

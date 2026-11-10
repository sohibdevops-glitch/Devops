output "id" {
  value = azurerm_app_configuration.appconfig.id
}

output "keys" {
  value = keys(var.app_config_key_value)
}

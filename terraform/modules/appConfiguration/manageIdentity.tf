# resource "azurerm_role_assignment" "appconf_data_owner" {
#   scope                = azurerm_app_configuration.appconfig.id
#   role_definition_name = "App Configuration Data Owner"
#   principal_id         = var.identity_id

#   depends_on = [
#     azurerm_app_configuration.appconfig
#   ]
# }

output "id" {
  value = azurerm_container_registry.acr.id
}

output "name" {
  value = azurerm_container_registry.acr.name
}

output "url" {
  value = "${azurerm_container_registry.acr.name}.azurecr.io"
}
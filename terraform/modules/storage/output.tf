output "storage_id" {
  value = azurerm_storage_account.main.id
}

output "primary_connection_string" {
  value     = azurerm_storage_account.main.primary_connection_string
  sensitive = true
}

output "automation_account_id" {
  value = azurerm_automation_account.main.id
}

output "automation_account_hybrid_service_url" {
  description = "Use this URL for Hybrid Worker extension settings"
  value       = azurerm_automation_account.main.hybrid_service_url
}

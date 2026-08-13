resource "azurerm_container_registry" "acr" {
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  name = lower(replace(var.name, "/[^[:alnum:]]/", "")) # can only consist of lowercase letters and numbers

  admin_enabled = var.admin_enabled

  sku = "Premium" # Required for private endpoint

  public_network_access_enabled = false

  network_rule_bypass_option = "None"

  data_endpoint_enabled = true # Enable dedicated data endpoint

  retention_policy_in_days = 10

  lifecycle {
    ignore_changes = [tags]
  }
}
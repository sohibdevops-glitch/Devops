# 1) Automation Account (with managed identity)
resource "azurerm_automation_account" "main" {
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  name = var.name

  sku_name                      = var.sku_name
  public_network_access_enabled = true
  local_authentication_enabled  = false

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

# 2) Hybrid Runbook Worker Group
resource "azurerm_automation_hybrid_runbook_worker_group" "group" {
  name                    = var.hrw_group_name
  resource_group_name     = var.azure.resource_group_name
  automation_account_name = azurerm_automation_account.main.name
}

# 3) Register the VM as a Hybrid Runbook Worker in the group
# resource "azurerm_automation_hybrid_runbook_worker" "worker" {
#   worker_group_name           = azurerm_automation_hybrid_runbook_worker_group.group.name
#   worker_id                   = var.worker_id
#   resource_group_name         = var.azure.resource_group_name
#   automation_account_name     = azurerm_automation_account.main.name
#   vm_resource_id              = var.vm_id
# }

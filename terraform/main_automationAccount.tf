module "automation-account" {
  source = "./modules/automationAccount"

  azure = {
    resource_group_name = data.azurerm_resource_group.main.name
    location            = data.azurerm_resource_group.main.location
    tags                = local.tags
  }
  
  name = "aa-${local.prefix.generic}-${var.environment}"

  worker_id = local.envs[var.environment].automation_account.worker_id
  vm_id     = local.envs[var.environment].automation_account.vm_id
}
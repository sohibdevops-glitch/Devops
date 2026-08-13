module "adf" {
  source = "./modules/adf"

  for_each = local.env_vars.sub_envs

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags                = local.tags
  }

  name = "adf-${local.prefix.generic}-${each.key}"

  managed_private_endpoints = [
    {
      name               = "storage-reports"
      target_resource_id = module.storage_reports[each.key].storage_id
      subresource_name   = "blob"
    }
  ]

  github_configuration = {
    account_name       = "mckesson"
    branch_name        = each.key == "dev" ? "main" : "main_${each.key}" # dev is 'main' branch, other envs is 'main_<EnvName>'
    git_url            = "https://github.com"
    publishing_enabled = true
    repository_name    = "can-rbg-winterfell-apps.platform.datafactory"
    root_folder        = "/"
  }
}

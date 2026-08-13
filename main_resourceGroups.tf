data "azurerm_resource_group" "main" {
  name = local.main_resource_group_name
}

resource "azurerm_resource_group" "sub_env" {
  for_each = local.env_vars.sub_envs

  location = local.env_vars.location

  name = "${local.prefix.resource_group}-${each.key}"

  # Policy requires some tags to create resource group, so we just re-use same tags as on main rg
  tags = merge(local.tags, data.azurerm_resource_group.main.tags)

  lifecycle {
    ignore_changes = [tags]
  }
}

module "servicebus_namespace" {
  source = "./modules/serviceBus"

  for_each = local.env_vars.sub_envs

  azure = {
    tenant_id           = local.tenant_id
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location            = azurerm_resource_group.sub_env[each.key].location
    tags                = local.tags
  }

  # For service bus (prefix with sb...)
  name = "sb-${local.prefix.generic}-${each.key}"

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }
}

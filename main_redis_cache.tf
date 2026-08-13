module "azurerm_redis_cache" {
  source = "./modules/azRedisCache"

  for_each = local.env_vars.sub_envs
  
  name = "az-redis-cache-rbg-b2c-${each.key}"

  azure = {
    resource_group_name = azurerm_resource_group.sub_env[each.key].name
    location = azurerm_resource_group.sub_env[each.key].location
    tags = merge(azurerm_resource_group.sub_env[each.key].tags,
      {
        # Tag used to identify resources related to signout token functionality
        signout = "token"
    })
  }

  private_endpoint = {
    subnet_id          = azurerm_subnet.private_endpoints.id
    dns_zone_id_prefix = local.private_dns_zones_id_prefix
  }

}
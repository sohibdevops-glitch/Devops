# Private Endpoint
resource "azurerm_private_endpoint" "redisCache" {
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  name = "${var.name}-endpoint"

  subnet_id = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "${var.name}-connection"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_redis_cache.redis.id
    subresource_names              = ["redisCache"]
  }

  private_dns_zone_group {
    name                 = "global-shared-dns"
    private_dns_zone_ids = ["${var.private_endpoint.dns_zone_id_prefix}privatelink.redis.cache.windows.net"]
  }

  lifecycle {
    ignore_changes = [tags]
  }
}


# NOTE: the Name used for Redis needs to be globally unique
resource "azurerm_redis_cache" "redis" {
  name                 = lower(var.name) # can only consist of lowercase letters and numbers
  location             = var.azure.location
  resource_group_name  = var.azure.resource_group_name
  capacity             = var.redis_configs.capacity
  family               = var.redis_configs.family
  sku_name             = var.redis_configs.sku_name
  non_ssl_port_enabled = var.redis_configs.non_ssl_port_enabled
  minimum_tls_version  = var.redis_configs.minimum_tls_version

  public_network_access_enabled  = false

  tags = var.azure.tags

  redis_configuration {
  }
}

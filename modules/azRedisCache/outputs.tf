output "hostname" {
  value = azurerm_redis_cache.redis.hostname
}

output "redis_configuration" {
  value = azurerm_redis_cache.redis.redis_configuration
}

output "redis_version" {
  value = azurerm_redis_cache.redis.redis_version
}

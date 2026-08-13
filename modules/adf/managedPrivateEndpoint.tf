resource "azurerm_data_factory_managed_private_endpoint" "managed_private_endpoint" {
  for_each = { for obj in var.managed_private_endpoints : obj.name => obj }

  name                   = "mpep-${each.value.name}"
  data_factory_id        = azurerm_data_factory.adf.id
  target_resource_id     = each.value.target_resource_id
  subresource_name       = each.value.subresource_name
}

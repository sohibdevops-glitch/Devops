# Assume VNet already exist
data "azurerm_virtual_network" "vnet" {
  resource_group_name = local.env_vars.vnet.resource_group_name
  name                = local.env_vars.vnet.name
}

# Subnet - Private Endpoints
resource "azurerm_subnet" "private_endpoints" {
  resource_group_name  = data.azurerm_virtual_network.vnet.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name

  name = "${local.prefix.subnet}-private-endpoints"

  address_prefixes = [local.env_vars.subnets.private_endpoints]

  private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
}

# NSG - Private Endpoints
resource "azurerm_network_security_group" "private_endpoints" {
  resource_group_name = data.azurerm_virtual_network.vnet.resource_group_name
  location            = data.azurerm_virtual_network.vnet.location
  tags                = local.tags

  name = "nsg-${local.prefix.generic}-private-endpoints"

  lifecycle {
    ignore_changes = [tags]
  }
}

# Subnet/NSG Association
resource "azurerm_subnet_network_security_group_association" "private_endpoint" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}

resource "azurerm_key_vault" "key_vault" {
  name                = var.name
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  tenant_id = var.azure.tenant_id

  sku_name = var.sku

  enable_rbac_authorization     = false
  public_network_access_enabled = false
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7

  lifecycle {
    ignore_changes = [tags]
  }
}

# Access Policy must be unique to each object_id
resource "azurerm_key_vault_access_policy" "permissions" {
  for_each = var.permissions

  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = var.azure.tenant_id
  object_id    = each.value.object_id

  # Give all permission if manage; else if get give limted; else nothing
  secret_permissions = each.value.manage_secrets ? [
    "Get",
    "Set",
    "List",
    "Delete",
    "Purge",
    "Recover",
    "Backup",
    "Restore"
    ] : each.value.get_secrets ? [
    "Get",
    "List"
  ] : []

  # Give all permission if manage; else if use give limted; else nothing
  key_permissions = each.value.manage_keys ? [
    "Get",
    "List",
    "Update",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "GetRotationPolicy",
    "SetRotationPolicy",
    "Rotate",
    "UnwrapKey",
    "Encrypt",
    "Decrypt",
    "WrapKey",
    "Verify",
    "Sign",
    "Purge",
    "Release",
    ] : each.value.use_keys ? [
    "Get",
    "List",
    "Encrypt",
    "Decrypt",
    "Verify",
    "Sign",
    "UnwrapKey",
    "WrapKey",
  ] : []


  # Give all permission if manage; else if get give limted; else nothing
  certificate_permissions = each.value.manage_certificates ? [
    "Get",
    "List",
    "Update",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "ManageContacts",
    "ManageIssuers",
    "GetIssuers",
    "ListIssuers",
    "SetIssuers",
    "DeleteIssuers",
    "Purge",
    ] : each.value.use_certificates ? [
    "Get",
    "List"
  ] : []
}

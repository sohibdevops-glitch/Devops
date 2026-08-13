resource "azurerm_data_factory" "adf" {
  name                = var.name
  location            = var.azure.location
  resource_group_name = var.azure.resource_group_name
  tags                = var.azure.tags

  managed_virtual_network_enabled = true
  public_network_enabled          = false

  github_configuration {
    account_name       = var.github_configuration.account_name
    branch_name        = var.github_configuration.branch_name
    git_url            = var.github_configuration.git_url
    publishing_enabled = var.github_configuration.publishing_enabled
    repository_name    = var.github_configuration.repository_name
    root_folder        = var.github_configuration.root_folder
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_data_factory_integration_runtime_azure" "managed_ir" {
  name                = "ManagedIntegrationRuntime"
  location            = var.azure.location

  data_factory_id = azurerm_data_factory.adf.id

  virtual_network_enabled = true
}
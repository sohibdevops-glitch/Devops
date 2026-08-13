# resource "null_resource" "update_tags" {
#   # The default behaviour on the resource is to apply the tags on creation and then ignore any changes.
#   # This is so Terraform doesn't trigger again because an Azure policy added tags and now Terraform wants to remove them.
#   # The below command will update only our tags if they change
#   provisioner "local-exec" {
#     command = <<EOT
#       az tag create --resource-id "${azurerm_storage_account.main.id}" --tags ${join(" ", [for k, v in var.azure.tags : "${k}=${v}"])}
#     EOT
#     #interpreter = ["/bin/bash", "-c"]
#   }

#   # Re-trigger only when tags changed
#   triggers = {
#     tags = jsonencode(var.azure.tags)
#   }
# }

# Note this doesn't work in pipeline because it's not authenticated with Azure CLI

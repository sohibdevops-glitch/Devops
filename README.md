# Terraform - Azure

Terraform files in this folder are used to setup Azure resources (Storages, ACR, AKS, etc.)

## Requirements

* Azure CLI
* Terraform

##  Running Terraform Locally

We assume you already:
 * Installed Azure CLI
 * Ran `az login` to log into your account/subscription
 * Have proper (admin) privileges to Azure

**Note:** Terraform will use the active Azure CLI subscription, if you need to change it:
```bash
az account show # Show current/active subscription
az account list # Display all subscriptions
az account set --name <GUID or Name>  # Set a subscription to be the current active subscription
```

### Naming Convention

```
<azure service>-<product/application group>-<context>-<region>-<environment>
```

See: [OC-Azure Naming Standard](../docs/OC-Azure%20Naming%20Standard-210525-145524.pdf)

### Initialize

First time running Terraform or when you want to change environment, run this PowerShell script:  
`./init.ps1 nonprod`  
or  
`./init.ps1 prod`  

Subsequent times, when loading new modules, you can just run:  
`terraform init`

### Check Changes

`terraform plan`

### Apply Changes

`terraform apply`

## (Optional) New Subscription Setup Steps. Skip when working with an existing subscription.

1. In `provider.tf`, you must comment the **backend** block. We can't use Azure storage for the initial creation.  
   Example:
   ```python
   # backend "azurerm" {
   # [...]
   # }
   ```

1. Run `./init.ps1 <env>` where `<env>` is either `nonprod` or `prod`

1. (Optional) If you have existing resources you can import them by adding import blocks into any Terraform file.  
   Example:
   ```python
   import {
     to = azurerm_resource_group.sub_env["prd"]
     id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-prd"
   }
   import {
     to = azurerm_resource_group.sub_env["preprd"]
     id = "/subscriptions/0d8f4db7-06d4-4f7f-9083-7827cff44449/resourceGroups/rg-rbg-b2c-winterfell-preprd"
   }
   ```

1. Run `terraform apply` to create the resources.

1. (Optional) Remove any `import` blocks you may have created in previous step.

1. In `provider.tf`, uncomment the **backend** block.

1. Run `./init.ps1 <env>` where `<env>` is either `nonprod` or `prod`.  
   It will ask to "copy existing state to the new backend?"  
   Answer `yes`


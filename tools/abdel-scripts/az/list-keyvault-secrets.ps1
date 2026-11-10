param (
    [string]$KeyVaultName = "YourKeyVaultName"
)

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI is not installed. Please install it from https://aka.ms/installazurecli"
    exit 1
}

# Ensure you're logged in
az account show > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Logging in to Azure..."
    az login
}

# List all secrets in the Key Vault
$secrets = az keyvault secret list --vault-name $KeyVaultName | ConvertFrom-Json

# Loop through each secret and get its value
foreach ($secret in $secrets) {
    $secretName = $secret.name
    $secretValue = az keyvault secret show --vault-name $KeyVaultName --name $secretName | ConvertFrom-Json
    Write-Host "Secret Name: $secretName"
    Write-Host "Secret Value: $($secretValue.value)"
    Write-Host "----------------------------------------"
}

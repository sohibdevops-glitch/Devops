#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Scans Azure App Configuration for placeholder-style keys (<<...>>) 
    and verifies whether they exist in the main ConfigurationJson secret 
    or in tenant Key Vaults.

.DESCRIPTION
    1. Retrieves all App Configuration key-values (unlabeled and labeled).
    2. Filters keys whose values contain the placeholder pattern <<...>>.
    3. Loads and parses the ConfigurationJson secret from the main (-mk) Key Vault.
    4. For each matching key:
        - If not tenant-specific, checks existence in ConfigurationJson.
        - If tenant-specific (tenant:xx:...), checks existence in the tenant's Key Vault.
    5. Outputs a summary table including a ❌ icon for keys missing in both locations.
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$Env
)

switch ($Env) {
    "prd" { 
        az account set -n "mck-canada-b2c-prod"
        $Region = "cacentral"
    }
    "preprd" { 
        az account set -n "mck-canada-b2c-prod"
        $Region = "cacentral"
    }
    "uat" { 
        az account set -n "mt-canada-b2c-nonprod"
        $Region = "caeast"
    }
    "dev" {
        az account set -n "mt-canada-b2c-nonprod"
        $Region = "caeast"
    }
    default { Write-Error "Unknown environment $Env. Must be one of: dev, uat, preprd, prd."; exit 1 }
}

$AppConfigName = "ac-rbg-b2c-winterfell-$Region-$Env"
$KeyVaultPrefix = "kv-rbg-b2c-$Env"   # e.g. tenant vaults = "$KeyVaultPrefix-xx"; main = "$KeyVaultPrefix-mk"
$SearchPattern = "(?:<<.*?>>|\\u003c\\u003c.*?\\u003e\\u003e)" #"<<.*>>"
$MainKVName = "$KeyVaultPrefix-mk"

# ========================
# Helper: fetch ALL KVs (paging + labels)
# - Get unlabeled (null label = \0) and labeled ("*"), then merge/dedupe
# ========================
function Get-AllAppConfigKVs {
    param($StoreName)

    # Unlabeled (null label)
    $unlabeled = az appconfig kv list `
        --name $StoreName `
        --label `\0 `
        --all `
        --query "[].{Key:key,Label:label,Value:value}" `
        --output json | ConvertFrom-Json

    # All labeled (wildcard)
    $labeled = az appconfig kv list `
        --name $StoreName `
        --label "*" `
        --all `
        --query "[].{Key:key,Label:label,Value:value}" `
        --output json | ConvertFrom-Json

    # Merge + dedupe by Key+Label
    $all = @()
    if ($unlabeled) { $all += $unlabeled }
    if ($labeled) { $all += $labeled }

    $all | Group-Object -Property Key, Label | ForEach-Object { $_.Group[0] }
}

# ========================
# 1) Get ALL key/values
# ========================
Write-Host "Fetching all key-values (paged) from App Configuration '$AppConfigName'..."
$appConfigItems = Get-AllAppConfigKVs -StoreName $AppConfigName

Write-Host "Loaded $($appConfigItems.Count) configs"

# Filter where value contains <<...>>
$matchingItems = $appConfigItems | Where-Object { $_.Value -match $SearchPattern }

# Write-Host "`n=== Keys with pattern '<<...>>' ==="
# $matchingItems | ForEach-Object {
#     Write-Host ("Key: {0} (Label: {1}) | Value: {2}" -f $_.Key, ($_.Label ?? "<null>"), $_.Value)
# }

# ========================
# 2) Load ConfigurationJson from main (-mk) vault
# ========================
Write-Host "`nFetching ConfigurationJson from $MainKVName..."
$mainConfigSecret = az keyvault secret show `
    --vault-name $MainKVName `
    --name "ConfigurationJson" `
    --query value `
    --output tsv 2>$null

$mainConfigJson = $null
if ($LASTEXITCODE -eq 0 -and $mainConfigSecret) {
    try { $mainConfigJson = $mainConfigSecret | ConvertFrom-Json -ErrorAction Stop }
    catch { Write-Warning "Could not parse ConfigurationJson from $MainKVName" }
}
else {
    Write-Warning "Could not retrieve ConfigurationJson from $MainKVName"
}

# ========================
# 3) Evaluate each matching key
# ========================
$results = @()

foreach ($item in $matchingItems) {
    $key = $item.Key
    $value = $item.Value
    $foundInMainKV = $false
    $foundInTenantKV = $false

    if ($key -notmatch "^tenant:[a-z]{2}:") {
        # Check in main MK vault JSON
        if ($mainConfigJson -and ($mainConfigJson.PSObject.Properties.Name -contains $key)) {
            $foundInMainKV = $true
        }
        else {
            Write-Warning "Key '$key' not found in ConfigurationJson of $MainKVName"
        }
    }
    else {
        # Tenant-specific: extract code and look up secret in <prefix>-xx
        if ($key -match "^tenant:([a-z]{2}):(.+)$") {
            $tenantCode = $matches[1]
            $restOfKey = $matches[2] -replace "_", "----" -replace ":", "--" 
            $tenantKVName = "$KeyVaultPrefix-$tenantCode"

            $tenantSecret = az keyvault secret show `
                --vault-name $tenantKVName `
                --name $restOfKey `
                --query value `
                --output tsv 2>$null

            if ($LASTEXITCODE -eq 0 -and $tenantSecret) {
                $foundInTenantKV = $true
            }
            else {
                Write-Warning "Secret '$restOfKey' not found in tenant KV: $tenantKVName"
            }
        }
    }

    $results += [PSCustomObject]@{
        Key     = $key
        Value   = $value
        InJson  = $foundInMainKV
        InVault = $foundInTenantKV
        Missing = if (-not $foundInMainKV -and -not $foundInTenantKV) { '❌' } else { '' }
    }
}

# ========================
# 4) Print summary table
# ========================
Write-Host "`n=== Summary Table ==="
$results | Format-Table -AutoSize

#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Ensures tenant Key Vaults contain the same set of secrets and shows a compact, aligned presence matrix.

.DESCRIPTION
    1) Discovers tenant Key Vaults matching "$KeyVaultPrefix-xx".
    2) Lists all secret names per vault (optional filters available).
    3) Builds the union of all secret names across vaults.
    4) Outputs a compact, emoji-based matrix (✅ present / ❌ missing) with fixed-width tenant columns for better alignment.
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
        $Region = "cacentral"
    }
    "dev" {
        az account set -n "mt-canada-b2c-nonprod"
        $Region = "caeast"
    }
    default { Write-Error "Unknown environment $Env. Must be one of: dev, uat, preprd, prd."; exit 1 }
}

$KeyVaultPrefix = "kv-rbg-b2c-$Env"   # e.g. kv-rbg-b2c-prd-xx

# Optional filters:
$LikePattern = "*"        # Compare only secrets matching this -Like pattern (default: all)
$IgnoreRegex = $null      # Regex to skip certain secrets (e.g., '^(?:AzureADApp|acme-).*$')

# ========================
# Discover tenant Key Vaults
# ========================
Write-Host "Discovering tenant Key Vaults for prefix '$KeyVaultPrefix-'..."
$allKvNames = az keyvault list --query "[].name" --output tsv 2>$null
$tenantKvNames = @($allKvNames | Where-Object { $_ -match "^$([regex]::Escape($KeyVaultPrefix))-[a-z]{2}$" })

if (-not $tenantKvNames -or $tenantKvNames.Count -eq 0) {
    Write-Warning "No tenant Key Vaults found for prefix '$KeyVaultPrefix-xx'."
    return
}

Write-Host "Found $($tenantKvNames.Count) tenant Key Vault(s): $($tenantKvNames -join ', ')"

# Map vault -> secrets and tenant codes
$vaultSecrets = @{}
$tenantCodes  = @{}

foreach ($kv in $tenantKvNames) {
    $tenantCode = ($kv -replace "^$([regex]::Escape($KeyVaultPrefix))-", "")
    $tenantCodes[$tenantCode] = $kv

    $names = az keyvault secret list `
        --vault-name $kv `
        --query "[].name" `
        --output tsv 2>$null

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to list secrets for vault '$kv'."
        $vaultSecrets[$tenantCode] = @()
        continue
    }

    $filtered = @($names | Where-Object { $_ -like $LikePattern })
    if ($IgnoreRegex) {
        $filtered = @($filtered | Where-Object { $_ -notmatch $IgnoreRegex })
    }

    $vaultSecrets[$tenantCode] = @([System.Linq.Enumerable]::Distinct([string[]]$filtered)) | Sort-Object
    Write-Host ("{0}: {1} secret(s) after filtering." -f $tenantCode, $vaultSecrets[$tenantCode].Count)
}

# ========================
# Union of all secrets
# ========================
$allSecrets = @([System.Linq.Enumerable]::Distinct([string[]](
    $vaultSecrets.Values | ForEach-Object { $_ }))) | Sort-Object

Write-Host ("Union of secrets across vaults: {0}" -f $allSecrets.Count)

# ========================
# Build matrix view (✅/❌ per tenant code)
# ========================
$MarkPresent = '✅'
$MarkMissing = '❌'

$matrix = @()

foreach ($secret in $allSecrets) {
    $row = [ordered]@{ Secret = $secret }
    foreach ($tenantCode in ($tenantCodes.Keys | Sort-Object)) {
        $row[$tenantCode] = if ($vaultSecrets[$tenantCode] -contains $secret) { $MarkPresent } else { $MarkMissing }
    }
    $matrix += [PSCustomObject]$row
}

# ---- Output with fixed-width tenant columns (emoji, width=4) ----
Write-Host "`n=== Presence Matrix (✅ present / ❌ missing) ==="

try { $winWidth = [Console]::WindowWidth } catch { $winWidth = 120 }
$secretWidth = [Math]::Max(30, [Math]::Min(80, $winWidth - ((4 + 1) * ($tenantCodes.Count + 1))))

$cols = @()
$cols += @{ Label = 'Secret'; Expression = { $_.Secret }; Width = $secretWidth; Alignment = 'Left' }

foreach ($t in ($tenantCodes.Keys | Sort-Object)) {
    # Force a plain string for the label
    $name = [string]$t
    # Build a scriptblock that returns $_.$name without capturing by reference
    $expr = [scriptblock]::Create("`$_.`"$name`"")
    $cols += @{ Label = $name; Expression = $expr; Width = 4; Alignment = 'Center' }
}

$matrix | Format-Table -Property $cols -AutoSize:$false


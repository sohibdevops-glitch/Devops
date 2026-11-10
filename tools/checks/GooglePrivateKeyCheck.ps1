#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates Firestore private key secrets in each tenant Key Vault against
    the private_key field of the AskService--Firestore--GoogleCredential secret.

.DESCRIPTION
    1. Discovers all tenant Key Vaults matching the "$KeyVaultPrefix-xx" naming convention.
    2. For each tenant Key Vault:
        - Loads and parses AskService--Firestore--GoogleCredential JSON to extract the .private_key value.
        - Lists all secrets matching "*--Firestore--private----key".
        - Compares each secret's value to the extracted private_key (with normalization for newline differences).
    3. Outputs a table showing tenant, vault, secret name, match status (✅/❌), and notes.
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

$KeyVaultPrefix = "kv-rbg-b2c-$Env"   # tenant vaults follow "$KeyVaultPrefix-xx" (e.g. kv-rbg-b2c-prd-ab)

# ========================
# Helper: normalize private key text for robust comparisons
# - Converts literal "\n" to real newlines
# - Normalizes CRLF/LF, trims edges
# ========================
function Normalize-Key {
    param([string]$s)
    if (-not $s) { return $null }
    $t = $s -replace "`r`n", "`n"         # CRLF -> LF
    $t = $t -replace "\\n", "`n"          # literal \n -> LF
    return $t.Trim()
}

# ========================
# Discover tenant Key Vaults for this env
# Regex: ^$KeyVaultPrefix-[a-z]{2}$  -> two-letter tenant code
# ========================
Write-Host "Discovering tenant Key Vaults for prefix '$KeyVaultPrefix-'..."
$allKvNames = az keyvault list --query "[].name" --output tsv 2>$null
$tenantKvNames = @($allKvNames | Where-Object { $_ -match "^$([regex]::Escape($KeyVaultPrefix))-[a-z]{2}$" })

if (-not $tenantKvNames -or $tenantKvNames.Count -eq 0) {
    Write-Warning "No tenant Key Vaults found for prefix '$KeyVaultPrefix-xx'."
    return
}

Write-Host "Found $($tenantKvNames.Count) tenant Key Vault(s)."

# ========================
# For each tenant KV:
# 1) Load AskService--Firestore--GoogleCredential (JSON) and extract .private_key
# 2) Find all secrets matching *--Firestore--private----key
# 3) Compare each value to the private_key; record results
# ========================
$results = @()

foreach ($kvName in $tenantKvNames) {
    # derive two-letter tenant code from the vault name suffix
    $tenantCode = ($kvName -replace "^$([regex]::Escape($KeyVaultPrefix))-", "")

    # -- 1) Get GoogleCredential.private_key
    $gcSecretRaw = az keyvault secret show `
        --vault-name $kvName `
        --name "AskService--Firestore--GoogleCredential" `
        --query value `
        --output tsv 2>$null

    $gcPrivateKey = $null
    $gcLoadError  = $null
    if ($LASTEXITCODE -eq 0 -and $gcSecretRaw) {
        try {
            $gcJson = $gcSecretRaw | ConvertFrom-Json -ErrorAction Stop
            $gcPrivateKey = Normalize-Key ($gcJson.private_key)

            Write-Host "Vault '$kvName' GoogleCredential Project Id: $($gcJson.project_id)"

            if (-not $gcPrivateKey) {
                $gcLoadError = "GoogleCredential JSON present but .private_key is null/empty."
            }
        } catch {
            $gcLoadError = "Failed to parse GoogleCredential as JSON."
        }
    } else {
        $gcLoadError = "Missing AskService--Firestore--GoogleCredential."
    }

    # -- 2) List Firestore private key secrets
    $secretNames = az keyvault secret list `
        --vault-name $kvName `
        --query "[].name" `
        --output tsv 2>$null

    if ($LASTEXITCODE -ne 0) {
        $results += [PSCustomObject]@{
            Tenant    = $tenantCode
            Vault     = $kvName
            Secret    = "<list failed>"
            Matches   = ''
            Status    = '❌'
            Note      = 'Failed to list secrets.'
        }
        continue
    }

    $fsPrivateKeyNames = @($secretNames | Where-Object { $_ -like "*--Firestore--private----key" })

    if (-not $fsPrivateKeyNames -or $fsPrivateKeyNames.Count -eq 0) {
        $results += [PSCustomObject]@{
            Tenant    = $tenantCode
            Vault     = $kvName
            Secret    = "<none matching *--Firestore--private----key>"
            Matches   = ''
            Status    = '❌'
            Note      = 'No matching Firestore private key secrets.'
        }
        continue
    }

    foreach ($secretName in $fsPrivateKeyNames) {
        $secretValRaw = az keyvault secret show `
            --vault-name $kvName `
            --name $secretName `
            --query value `
            --output tsv 2>$null

        if ($LASTEXITCODE -ne 0 -or -not $secretValRaw) {
            $results += [PSCustomObject]@{
                Tenant  = $tenantCode
                Vault   = $kvName
                Secret  = $secretName
                Matches = ''
                Status  = '❌'
                Note    = 'Secret not found or empty.'
            }
            continue
        }

        $secretVal = Normalize-Key $secretValRaw

        if ($gcLoadError) {
            $results += [PSCustomObject]@{
                Tenant  = $tenantCode
                Vault   = $kvName
                Secret  = $secretName
                Matches = ''
                Status  = '❌'
                Note    = $gcLoadError
            }
            continue
        }

        # -- 3) Compare normalized values
        $isMatch = $false
        if ($gcPrivateKey -and $secretVal) {
            $isMatch = ($gcPrivateKey -eq $secretVal)
        }

        $results += [PSCustomObject]@{
            Tenant  = $tenantCode
            Vault   = $kvName
            Secret  = $secretName
            Matches = if ($isMatch) { '✅' } else { '❌' }
            Status  = if ($isMatch) { 'OK' } else { '⚠️' }
            Note    = if ($isMatch) { '' } else { 'Value differs from GoogleCredential.private_key' }
        }
    }
}

# ========================
# Summary table
# ========================
Write-Host "`n=== Firestore Private Key Verification ==="
$results |
    Sort-Object Tenant, Secret |
    Select-Object Tenant, Vault, Secret, Matches, Status, Note |
    Format-Table -AutoSize

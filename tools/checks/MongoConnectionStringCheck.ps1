#!/usr/bin/env pwsh

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

# ========================
# Config
# ========================
$KeyVaultPrefix = "kv-rbg-b2c-$Env"   # tenant vaults follow "$KeyVaultPrefix-xx" (e.g. kv-rbg-b2c-prd-ab)
$secretSuffixes = @('Mongo--ConnectionString')  # suffix filters
$explicitSecretNames = @('HealthtrackerService--Persistence--ValidicUsers--ConnectionString')  # exact-name checks

# ========================
# Helpers
# ========================

function Get-NormalizedMongoKey {
    <#
      Returns a normalized key used for equality:
        user|password|host(first, no port, lowercased)
      - Supports mongodb:// and mongodb+srv://
      - Ignores db names and query params
      - URL-decodes user/pass
      - If parse fails, returns ''
    #>
    param([string]$ConnStr)

    if ([string]::IsNullOrWhiteSpace($ConnStr)) { return '' }

    $pattern = '^(mongodb(?:\+srv)?):\/\/(?:(?<user>[^:@\/\?]+):(?<pass>[^@\/\?]+)@)?(?<hosts>[^\/\?]+)'
    $m = [regex]::Match($ConnStr, $pattern, 'IgnoreCase')
    if (-not $m.Success) { return '' }

    # URL-decode user/pass (do NOT lowercase them; passwords are case-sensitive)
    $user = $m.Groups['user'].Value
    $pass = $m.Groups['pass'].Value
    try {
        $user = [System.Net.WebUtility]::UrlDecode($user)
        $pass = [System.Net.WebUtility]::UrlDecode($pass)
    } catch {}

    # Take first host only; strip :port; host compare is case-insensitive -> lowercase host only
    $hosts = $m.Groups['hosts'].Value
    $firstHost = ($hosts -split ',')[0]
    $hostNoPort = ($firstHost -split ':')[0].ToLowerInvariant()

    return "$user|$pass|$hostNoPort"
}

function Mask-SecretValue {
    <#
      Masks a sensitive string for display: preserves length & first 2 chars if length > 4
    #>
    param([string]$s)
    if ([string]::IsNullOrEmpty($s)) { return '' }
    if ($s.Length -le 4) { return ('*' * $s.Length) }
    return $s.Substring(0,2) + ('*' * ($s.Length - 2))
}

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

Write-Host "Found $($tenantKvNames.Count) tenant Key Vault(s)."

# Map: VaultName -> ArrayList of entries per secret in that vault
# Entry: {Vault,TenantCode,SecretName,ValueRaw,ValueNorm,NormUser,NormPass,NormHost}
$secretsByVault = @{}

foreach ($kvName in $tenantKvNames) {
    $tenantCode = ($kvName -replace "^$([regex]::Escape($KeyVaultPrefix))-", "")
    Write-Host "`n[$kvName] ($tenantCode): scanning secrets..."

    # Pull all secret names once, then filter by suffix OR explicit names
    $allSecretNames = az keyvault secret list --vault-name $kvName --query "[].name" --output tsv 2>$null

    if (-not $allSecretNames) {
        Write-Host "  (no secrets found in vault)"
        continue
    }

    $matchedBySuffix = foreach ($suffix in $secretSuffixes) {
        $allSecretNames | Where-Object { $_.EndsWith($suffix) }
    }

    $matchedExplicit  = $allSecretNames | Where-Object { $explicitSecretNames -contains $_ }

    $secretNames = @() + $matchedBySuffix + $matchedExplicit | Select-Object -Unique

    if (-not $secretNames -or $secretNames.Count -eq 0) {
        Write-Host "  (none matched suffixes or explicit names)"
        continue
    }

    foreach ($sName in $secretNames) {
        $value = az keyvault secret show --vault-name $kvName --name $sName --query "value" -o tsv 2>$null
        $norm  = Get-NormalizedMongoKey -ConnStr $value

        $parts = if (-not [string]::IsNullOrWhiteSpace($norm)) { $norm -split '\|' } else { @('','','') }

        $entry = [pscustomobject]@{
            Vault      = $kvName
            TenantCode = $tenantCode
            SecretName = $sName
            ValueRaw   = $value
            ValueNorm  = $norm
            NormUser   = $parts[0]
            NormPass   = $parts[1]
            NormHost   = $parts[2]
        }

        if (-not $secretsByVault.ContainsKey($kvName)) {
            $secretsByVault[$kvName] = New-Object System.Collections.ArrayList
        }
        [void]$secretsByVault[$kvName].Add($entry)
    }
}

if ($secretsByVault.Keys.Count -eq 0) {
    Write-Warning "`nNo target secrets were found in any tenant Key Vault."
    return
}

# ========================
# Comparison & Output (per vault)
# ========================
$summary = @()

foreach ($kvName in ($secretsByVault.Keys | Sort-Object)) {
    $entries = $secretsByVault[$kvName]
    $tenant  = ($entries | Select-Object -First 1).TenantCode

    $uniqueNorms = ($entries | Where-Object { $_.ValueNorm -ne '' } |
                    Select-Object -ExpandProperty ValueNorm -Unique)

    $checkedCount = $entries.Count
    $parsedCount  = ($entries | Where-Object { $_.ValueNorm -ne '' }).Count

    if ($checkedCount -eq 0) {
        Write-Host "`n----------------------------------------------------------------"
        Write-Host "⚠  Vault: $kvName ($tenant)  ->  no target secrets found"
        Write-Host "----------------------------------------------------------------"
        continue
    }

    $allMatch = ($parsedCount -gt 0) -and ($uniqueNorms.Count -le 1)
    $icon     = if ($allMatch) { "✓" } else { "✗" }
    $status   = if ($allMatch) { "MATCH" } else { "DIFFER" }

    Write-Host "`n----------------------------------------------------------------"
    Write-Host "$icon  Vault: $kvName ($tenant)  ->  $status  |  $checkedCount secret(s) checked; $parsedCount parsed"
    Write-Host "----------------------------------------------------------------"

    $entries |
        Sort-Object SecretName |
        Select-Object `
            @{n='SecretName';e={$_.SecretName}},
            @{n='User';e={$_.NormUser}},
            @{n='Pass';e={ Mask-SecretValue $_.NormPass }},
            @{n='Host';e={$_.NormHost}},
            @{n='HasValue';e={ if ([string]::IsNullOrWhiteSpace($_.ValueRaw)) {'No'} else {'Yes'} }},
            @{n='Parsed';e={ if ([string]::IsNullOrWhiteSpace($_.ValueNorm)) {'No'} else {'Yes'} }} |
        Format-Table -AutoSize

    $summary += [pscustomobject]@{
        Vault          = $kvName
        Tenant         = $tenant
        SecretsChecked = $checkedCount
        Parsed         = $parsedCount
        StatusIcon     = $icon
        Status         = $status
        DistinctNorms  = $uniqueNorms.Count
    }
}

Write-Host "`n=== Summary (Per Vault) ==="
$summary | Sort-Object Vault | Format-Table -AutoSize

Write-Host "`nLegend: ✓ = all *within that vault* have identical user/password/first-host; ✗ = at least one differs or failed to parse."
Write-Host "Note: Comparison ignores DB name, replica set members beyond the first host, and query params."
Write-Host "Also checks explicit secret(s): $($explicitSecretNames -join ', ')."

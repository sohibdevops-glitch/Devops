#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Verifies that:
    1) ConfigurationJson["API:Key"] in the -mk Key Vault (with App Config fallback)
       matches BffConfiguration["api-key"] in the -devops Key Vault.
    2) BffConfiguration["loggly-key"] in the -devops Key Vault
       matches the secret 'Loggly--InputKey' in the -devops Key Vault.

.DESCRIPTION
  Base API key resolution order:
    - KV (-mk): secret "ConfigurationJson" -> ["API:Key"]
    - App Configuration: "ac-rbg-b2c-winterfell-$Region-$Env" -> key "API:Key" (unwrap JSON string)

  Output:
    - Table: Vault | Secret | Key | Status | Note  (✅ match, ⚠️ mismatch, ❌ error)
    - If mismatched, raw values are printed after the table on separate lines.
#>

param (
  [Parameter(Mandatory = $true)]
  [ValidateSet("dev","uat","preprd","prd")]
  [string]$Env
)

# Subscription / Region
switch ($Env) {
  "prd"     { az account set -n "mck-canada-b2c-prod";   $Region = "cacentral" }
  "preprd"  { az account set -n "mck-canada-b2c-prod";   $Region = "cacentral" }
  "uat"     { az account set -n "mt-canada-b2c-nonprod"; $Region = "cacentral" }
  "dev"     { az account set -n "mt-canada-b2c-nonprod"; $Region = "caeast" }
}

$KeyVaultPrefix = "kv-rbg-b2c-$Env"
$MkVault        = "$KeyVaultPrefix-mk"
$DevOpsVault    = "$KeyVaultPrefix-devops"
$AppConfigName  = "ac-rbg-b2c-winterfell-$Region-$Env"

# Helpers
function Get-SecretValue {
  param([string]$Vault,[string]$Name)
  $val = az keyvault secret show --vault-name $Vault --name $Name --query value --output tsv 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $val) { return $null }
  $val
}
function Parse-Json {
  param([string]$Raw)
  if (-not $Raw) { return $null }
  try { $Raw | ConvertFrom-Json -ErrorAction Stop } catch { $null }
}
function Get-AppConfigValue {
  param([string]$AppConfigName,[string]$Key)
  $val = az appconfig kv show --name $AppConfigName --key $Key --query value --output tsv 2>$null
  if ($LASTEXITCODE -eq 0 -and $val) { return $val }
  $val = az appconfig kv show --name $AppConfigName --key $Key --label "\0" --query value --output tsv 2>$null
  if ($LASTEXITCODE -eq 0 -and $val) { return $val }
  $val = az appconfig kv show --name $AppConfigName --key $Key --label "*" --query value --output tsv 2>$null
  if ($LASTEXITCODE -eq 0 -and $val) { return $val }
  $null
}

$results = @()

# 1) Try KV (-mk) ConfigurationJson -> ["API:Key"]
$baseApiKey = $null; $baseSource = $null; $cfgNote = $null
$cfgRaw  = Get-SecretValue -Vault $MkVault -Name "ConfigurationJson"
$cfgJson = Parse-Json $cfgRaw
if (-not $cfgRaw) {
  $cfgNote = "Missing or empty secret 'ConfigurationJson' in $MkVault."
} elseif (-not $cfgJson) {
  $cfgNote = "Failed to parse 'ConfigurationJson' in $MkVault as JSON."
} elseif ($cfgJson.PSObject.Properties.Name -contains 'API:Key') {
  $tmp = $cfgJson.'API:Key'
  if ($tmp) { $baseApiKey = $tmp.ToString().Trim(); if ($baseApiKey) { $baseSource = "ConfigurationJson"; $cfgNote = "Loaded base comparison key."; } else { $cfgNote = "'API:Key' present but empty." } }
  else { $cfgNote = "'API:Key' present but null." }
} else { $cfgNote = "'API:Key' property not found." }

$results += [PSCustomObject]@{
  Vault  = $MkVault
  Secret = "ConfigurationJson"
  Key    = "API:Key"
  Status = if ($baseSource -eq "ConfigurationJson") { '✅' } else { '❌' }
  Note   = $cfgNote
}

# 2) Fallback to App Configuration if needed
$appCfgNote = $null
if (-not $baseApiKey) {
  $acVal = Get-AppConfigValue -AppConfigName $AppConfigName -Key "API:Key"
  if ($acVal) {
    try { $parsedVal = $acVal | ConvertFrom-Json -ErrorAction Stop; if ($parsedVal -is [string]) { $acVal = $parsedVal } } catch {}
    $baseApiKey = $acVal.ToString().Trim()
    if ($baseApiKey) { $baseSource = "AppConfiguration"; $appCfgNote = "Loaded base key from App Configuration." } else { $appCfgNote = "App Configuration key found but empty." }
  } else { $appCfgNote = "Key 'API:Key' not found in App Configuration." }
}
$results += [PSCustomObject]@{
  Vault  = $AppConfigName
  Secret = "(AppConfig)"
  Key    = "API:Key"
  Status = if ($baseSource -eq "AppConfiguration") { '✅' } else { if ($appCfgNote) { '❌' } else { '' } }
  Note   = $appCfgNote
}
$baseReady = [bool]$baseApiKey

# Track mismatched values for post-table printing
$diffBaseValue = $null; $diffBffValue = $null
$diffLogglyBffValue = $null; $diffLogglySecretValue = $null

# 3) Read BffConfiguration (once) from -devops
$bfRaw  = Get-SecretValue -Vault $DevOpsVault -Name "BffConfiguration"
if (-not $bfRaw) {
  $results += [PSCustomObject]@{ Vault=$DevOpsVault; Secret="BffConfiguration"; Key="(json)"; Status='❌'; Note="Missing or empty secret." }
} else {
  $bfJson = Parse-Json $bfRaw
  if (-not $bfJson) {
    $results += [PSCustomObject]@{ Vault=$DevOpsVault; Secret="BffConfiguration"; Key="(json)"; Status='❌'; Note="Failed to parse as JSON." }
  } else {
    # 3a) Compare API key
    if (-not ($bfJson.PSObject.Properties.Name -contains 'api-key')) {
      $results += [PSCustomObject]@{ Vault=$DevOpsVault; Secret="BffConfiguration"; Key="api-key"; Status='❌'; Note="Property 'api-key' not found." }
    } else {
      $bffApi = $bfJson.'api-key'
      if (-not $bffApi) {
        $results += [PSCustomObject]@{ Vault=$DevOpsVault; Secret="BffConfiguration"; Key="api-key"; Status='❌'; Note="'api-key' present but null/empty." }
      } elseif (-not $baseReady) {
        $results += [PSCustomObject]@{ Vault=$DevOpsVault; Secret="BffConfiguration"; Key="api-key"; Status='❌'; Note="Cannot compare: base 'API:Key' unavailable." }
      } else {
        $bffApi = $bffApi.ToString().Trim()
        $apiMatch = ($bffApi -eq $baseApiKey)
        if (-not $apiMatch) { $diffBaseValue = $baseApiKey; $diffBffValue = $bffApi }
        $results += [PSCustomObject]@{
          Vault  = $DevOpsVault
          Secret = "BffConfiguration"
          Key    = "api-key"
          Status = if ($apiMatch) { '✅' } else { '⚠️' }
          Note   = if ($apiMatch) { "Matched base from $baseSource." } else { "Differs from base value from $baseSource." }
        }
      }
    }

    # 3b) Compare Loggly key vs secret Loggly--InputKey
    if (-not ($bfJson.PSObject.Properties.Name -contains 'loggly-key')) {
      $results += [PSCustomObject]@{ Vault=$DevOpsVault; Secret="BffConfiguration"; Key="loggly-key"; Status='❌'; Note="Property 'loggly-key' not found." }
    } else {
      $bffLoggly = $bfJson.'loggly-key'
      if (-not $bffLoggly) {
        $results += [PSCustomObject]@{ Vault=$DevOpsVault; Secret="BffConfiguration"; Key="loggly-key"; Status='❌'; Note="'loggly-key' present but null/empty." }
      } else {
        $bffLoggly = $bffLoggly.ToString().Trim()
        $logglySecret = Get-SecretValue -Vault $DevOpsVault -Name "Loggly--InputKey"
        if (-not $logglySecret) {
          $results += [PSCustomObject]@{ Vault=$DevOpsVault; Secret="Loggly--InputKey"; Key="(secret)"; Status='❌'; Note="Missing or empty secret." }
        } else {
          $logglySecret = $logglySecret.ToString().Trim()
          $logglyMatch = ($bffLoggly -eq $logglySecret)
          if (-not $logglyMatch) { $diffLogglyBffValue = $bffLoggly; $diffLogglySecretValue = $logglySecret }
          $results += [PSCustomObject]@{
            Vault  = $DevOpsVault
            Secret = "Loggly--InputKey"
            Key    = "loggly-key"
            Status = if ($logglyMatch) { '✅' } else { '⚠️' }
            Note   = if ($logglyMatch) { "BffConfiguration['loggly-key'] matches Loggly--InputKey." } else { "BffConfiguration['loggly-key'] differs from Loggly--InputKey." }
          }
        }
      }
    }
  }
}

# Output
Write-Host "`n=== BFF Key Verification (with AppConfig fallback) ==="
$results | Select-Object Vault, Secret, Key, Status, Note | Format-Table -AutoSize

# Print raw values after table when mismatched
if ($diffBaseValue -and $diffBffValue) {
  Write-Host "`nBase API Key: $diffBaseValue"
  Write-Host "BFF API Key:  $diffBffValue"
}
if ($diffLogglyBffValue -and $diffLogglySecretValue) {
  Write-Host "`nBFF Loggly Key:   $diffLogglyBffValue"
  Write-Host "Secret Loggly Key: $diffLogglySecretValue"
}

# Exit non-zero if any non-✅ row
$hasProblem = $results | Where-Object { $_.Status -ne '✅' } | Measure-Object | Select-Object -ExpandProperty Count
if ($hasProblem -gt 0) { exit 1 } else { exit 0 }

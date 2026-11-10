#!/usr/bin/env pwsh

# Requires Powershell 7+

param (
    [Parameter(Mandatory = $true)]
    [string]$Vault,

    [Parameter(Mandatory = $false)]
    [string]$Filter = "*",

    [Parameter(Mandatory = $false)]
    [string]$Folder = ""
)

$ErrorActionPreference = "Stop"
# 🌈 Gotta have some colors !
$Esc = [char]27
$Red     = "${Esc}[31m"
$Green   = "${Esc}[32m"
$Yellow  = "${Esc}[33m"
$Blue    = "${Esc}[34m"
$Magenta = "${Esc}[35m"
$Reset   = "${Esc}[0m"

$DataFolder="data"
$MaxParallel=10
$ExpirationDate="2099-01-01T00:00:00Z"

if ($Folder -eq "") {
    $VaultDataFolder="$DataFolder\$Vault"
} else {
    $VaultDataFolder = "$DataFolder\$Folder"
}

if (-Not (Test-Path -Path $VaultDataFolder)) {
    Write-Error "Local KeyVault folder doesn't exist $VaultDataFolder"
    exit 1
}

Write-Host "Load secrets of vault $Yellow$Vault$Reset"
$SecretList = az keyvault secret list --vault-name $Vault | ConvertFrom-Json
$SecretsToPush = Get-ChildItem -Path $VaultDataFolder


if ($Filter -ne "*") {
    $regexPattern = "^" + ([Regex]::Escape($Filter) -replace '\\\*', '.*') + "$"
    $SearchRegex = [regex]::new($regexPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    Write-Host "Filtering secrets with pattern: $regexPattern"

    $SecretList = $SecretList | Where-Object { $SearchRegex.IsMatch($_.Name) }
    $SecretsToPush = $SecretsToPush | Where-Object { $SearchRegex.IsMatch($_.Name) }
}

Write-Host "Found $Magenta$($SecretList.Count)$Reset existing secrets in vault"
Write-Host "Set $Magenta$($SecretsToPush.Count)$Reset secrets from $Green$VaultDataFolder$Reset"

$confirm = Read-Host "Are you sure you want to proceed? (Y/N)"
if ($confirm -ne 'Y') {
    Write-Host "Aborted"
    exit 0
}

$SecretsToPush | ForEach-Object -ThrottleLimit $MaxParallel -Parallel {
  $SecretName = $_.Name
  Write-Host "Set: $using:Blue$SecretName$using:Reset"
  $Result = az keyvault secret set --vault-name $using:Vault --name $SecretName --file $_.FullName --encoding utf-8 --expires "$using:ExpirationDate"
  if ($Result -eq $null) {
    Write-Host "$using:Red Failed to push secret $SecretName$Reset"
  }
}
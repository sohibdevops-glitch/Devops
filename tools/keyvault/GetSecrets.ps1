#!/usr/bin/env pwsh

# Requires Powershell 7+

param (
    [Parameter(Mandatory = $true)]
    [string]$Vault,

    [Parameter(Mandatory = $false)]
    [string]$Folder = "",

    [Parameter(Mandatory = $false)]
    [string]$Filter = "*",

    [Parameter(Mandatory = $false)]
    [switch]$Show = $false # If true, will only show the secrets
)

$ErrorActionPreference = "Stop"
# 🌈 Gotta have some colors !
$Esc = [char]27
$Red = "${Esc}[31m"
$Green = "${Esc}[32m"
$Yellow = "${Esc}[33m"
$Blue = "${Esc}[34m"
$Magenta = "${Esc}[35m"
$Reset = "${Esc}[0m"

$DataFolder = "data"
$MaxParallel = 10

Write-Host "Load secrets of vault $Yellow$Vault$Reset"
$SecretList = az keyvault secret list --vault-name $Vault | ConvertFrom-Json

if ($Folder -eq "") {
    $VaultDataFolder = "$DataFolder\$Vault"
}
else {
    $VaultDataFolder = "$DataFolder\$Folder"
}

if ($SecretList -And -Not (Test-Path -Path $VaultDataFolder)) {
    $null = New-Item -ItemType Directory -Path $VaultDataFolder
    Write-Host "Created folder $VaultDataFolder"
}

if ($Filter -ne "*") {
    $regexPattern = "^" + ([Regex]::Escape($Filter) -replace '\\\*', '.*') + "$"
    $SearchRegex = [regex]::new($regexPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    Write-Host "Filtering secrets with pattern: $regexPattern"
    $SecretList = $SecretList | Where-Object { $SearchRegex.IsMatch($_.Name) }
}

Write-Host "Found $Magenta$($SecretList.Count)$Reset secrets, $($Show ? "${Green}showing${Reset} secrets" : "${Green}writing$Reset to $Green$VaultDataFolder$Reset" )"

$confirm = Read-Host "Are you sure you want to proceed? (Y/N)"
if ($confirm -ne 'Y') {
    Write-Host "Aborted"
    exit 0
}

$SecretList | ForEach-Object -ThrottleLimit $MaxParallel -Parallel {
    $SecretName = $_.Name

    $Secret = az keyvault secret show --vault-name $using:Vault --name $SecretName --query "value" --output tsv
    if ($using:Show) {
        Write-Host "$using:Blue$SecretName$using:Reset = $using:Green$Secret$using:Reset"
    }
    else {
        Write-Host "Get: $using:Blue$SecretName$using:Reset"
        Set-Content -Path "$using:VaultDataFolder\$SecretName" -Value $Secret -Encoding utf8 -NoNewline
    }
}
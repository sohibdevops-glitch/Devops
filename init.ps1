#!/usr/bin/env pwsh

param (
    [Parameter(Mandatory = $false)]
    [string]$DeployEnv
)

$ErrorActionPreference = "Stop"
$ClearState = $false
$TfVarsFile = "terraform.tfvars"
$AllowedEnvironments = @('nonprod', 'prod')

function Get-TerraformVariables {
    param (
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        return
    }

    $variables = @{}

    Get-Content $FilePath | ForEach-Object {
        $Line = $_.Trim()

        # Ignore comments and empty lines
        if ($Line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($Line)) {
            return
        }

        # Match key = "value" pattern
        if ($Line -match '^(\S+)\s*=\s*"(.+)"$') {
            $key = $matches[1]
            $value = $matches[2]
            $variables[$key] = $value
        }
    }

    return $variables
}

function Update-TerraformVariable {
    param (
        [string]$FilePath,
        [string]$VarName,
        [string]$VarValue,
        [bool]$HideValue = $false
    )

    if (Test-Path $FilePath) {
        # Read file line by line
        $updatedContent = Get-Content $FilePath | ForEach-Object {
            if ($_.Trim().StartsWith('#')) {
                $_  # Ignore comment line
            }
            elseif ($_ -match "^\s*$VarName\s*=.*") {
                # If line matches variable, redefine with value
                "$VarName = `"$VarValue`""
                $Found = $true
            }
            else {
                $_  # Keep lines unchanged
            }
        }
    }
    else {
        $updatedContent = ""
    }

    # If not found in content
    if (!$Found) {
        # Add to end of file
        $updatedContent += "$VarName = `"$VarValue`""
    }

    if ($HideValue) {
        $VarValue = "****"
    }

    Write-Warning "Writing $VarName = `"$VarValue`" to $FilePath"
    $updatedContent | Set-Content $FilePath
}

function AskForArg {
    param (
        [string]$ArgValue,
        [string]$VarName,
        [string]$AskText,
        [ref]$ClearStateRef,
        [ScriptBlock]$Validator = $null
    )

    # Check input
    if ($ArgValue -and $Validator -ne $null -and -not (& $Validator $ArgValue)) {
        exit 1
    }

    if (!$ArgValue -and (!$TfVars -or !$TfVars[$VarName])) {
        # When no arg and no value in file, ask
        $userInput = Read-Host "$AskText"

        if ($Validator -ne $null -and -not (& $Validator $userInput)) {
            exit 1
        }

        Update-TerraformVariable $TfVarsFile $VarName $userInput
        if ($ClearStateRef) {
            $ClearStateRef.Value = $true
        }
    }
    elseif ($ArgValue -and (!$TfVars -or $ArgValue -cne $TfVars[$VarName])) {
        # When arg provided but not the same in file, write to file
        Update-TerraformVariable $TfVarsFile $VarName $ArgValue
        if ($ClearStateRef) {
            $ClearStateRef.Value = $true
        }
    }
}

function Validate-Environment {
    param ($value)
    $IsValid = $AllowedEnvironments -ccontains $value

    if(!$IsValid) {
        Write-Host "Invalid environment, must be one of: $($AllowedEnvironments -join ', ')" -ForegroundColor Red
    }

    return $IsValid
}

# Read current vars
$TfVars = Get-TerraformVariables -FilePath $TfVarsFile

AskForArg $DeployEnv "environment" "Environment ? [$($AllowedEnvironments -join ', ')] ?" ([ref]$ClearState) ${function:Validate-Environment}

if ($ClearState) {
    $TfStateFile = ".terraform/terraform.tfstate"
    if (Test-Path $TfStateFile) {
        Write-Warning "Deleting state file: $TfStateFile"
        Remove-Item -Force $TfStateFile
    }
}

# Reload vars
$TfVars = Get-TerraformVariables -FilePath $TfVarsFile

# Define variables as in Readme.md scripts
$TFENV = $TfVars.environment

$PREFIX="rbg-b2c-winterfell"
if($TFENV -eq "prod") {
    $RESOURCE_GROUP = "rg-$PREFIX-prod-shared"
} else {
    $RESOURCE_GROUP = "rg-$PREFIX-nonprod"
}

$STORAGE_NAME = ("rbgb2ctfstate$($TFENV)" -replace '[^a-zA-Z0-9]', '').ToLower() # Max 24 char.

$C1 = "resource_group_name=$RESOURCE_GROUP"
$C2 = "storage_account_name=$STORAGE_NAME"

Write-Host "Environment: $TFENV"

Write-Host "Set subscription for this environment"
switch ($TFENV) {
    "nonprod" {
        az account set -n mt-canada-b2c-nonprod
        break
    }
     "prod" {
        az account set -n mck-canada-b2c-prod
        break
    }
    default {
        Write-Warning "No subscription defined for environment: $TFENV"
    }
}

# Print current Azure account details
$account = az account show --output json | ConvertFrom-Json
Write-Output "Azure Subscription:"
Write-Output "  Name: $($account.name)"
Write-Output "  GUID: $($account.id)"

Write-Output "Initializing Terraform..."
Write-Output "  $C1"
Write-Output "  $C2"

$CMD = "terraform init -backend-config $C1 -backend-config $C2"
Write-Host $CMD
Invoke-Expression $CMD

if ($LASTEXITCODE -ne 0) {
    Write-Host "Terraform init failed."
    exit 1
}
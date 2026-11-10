
param (
    [string]$AppConfigName
)

Write-Output "AppConfig : $($AppConfigName)"
az appconfig kv list --name $AppConfigName --output table

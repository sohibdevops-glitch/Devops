param (
    [Parameter(Mandatory = $true)]
    [string]$VaultName,

    [Parameter(Mandatory = $true)]
    [string]$InputFile
)

# Check if the input file exists
if (Test-Path $InputFile) {
    Write-Host "File found: $InputFile"

    # Read each line from the file
    Get-Content $InputFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and $line -match '^(.*?):\s*"(.*)"$') {
            $rawKey = $matches[1].Trim()
            $value = $matches[2].Trim()
            $formattedKey = $rawKey -replace ":", "--"

            Write-Host "PASS -  Setting secret: $formattedKey"

            # Set the secret in Azure Key Vault
            az keyvault secret set --vault-name $VaultName --name $formattedKey --value $value --expires "2099-12-31T23:59:59Z"
        } else {
            Write-Host "SKIP - Skipping malformed line: $line"
        }
    }
} else {
    Write-Host "X - File not found: $InputFile"
}
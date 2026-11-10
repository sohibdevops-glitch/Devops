# Key Vault Scripts

## GetSecrets.ps1
```powershell
# Download all secrets
./GetSecrets.ps1 'kv-rbg-b2c-dev'

# Download all secrets into another folder name
./GetSecrets.ps1 'kv-rbg-b2c-dev' -Folder 'test'

# Download only secrets that match the filter
./GetSecrets.ps1 'kv-rbg-b2c-dev' -Filter '*token*'

# Show secrets that match the filter
./GetSecrets.ps1 'kv-rbg-b2c-dev' -Filter '*token*' -Show
```

## SetSecrets.ps1
```powershell
# Set all secrets from local files
./SetSecrets.ps1 'kv-rbg-b2c-dev'

# Set all secrets from another folder
./SetSecrets.ps1 'kv-rbg-b2c-dev' -Folder 'test'

# Set only secrets that match the filter
./SetSecrets.ps1 'kv-rbg-b2c-dev' -Filter '*token*'
```

## CleanupNonSecrets.ps1

This script is used to remove KeyVault secrets that shouldn't be in KeyVault. They are duplicate values already defined in App Config.

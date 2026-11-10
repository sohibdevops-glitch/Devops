#!/usr/bin/env pwsh

# Requires Powershell 7+

param (
    [Parameter(Mandatory = $false)]
    [string]$Environment,

    [Parameter(Mandatory = $false)]
    [string]$OutFile,

    [Parameter(Mandatory = $false)]
    [switch]$Check,

    [Parameter(Mandatory = $false)]
    [string]$DnsServer = ""      # For Check
)

if ($Environment -eq "prod") {
    $SubscriptionNameId = "mck-canada-b2c-prod" 
    $ResourceGroups = @("rg-rbg-b2c-winterfell-prod-shared", "rg-rbg-b2c-winterfell-preprd", "rg-rbg-b2c-winterfell-prd")
}
elseif ($Environment -eq "nonprod") {
    $SubscriptionNameId = "mt-canada-b2c-nonprod"
    $ResourceGroups = @("rg-rbg-b2c-winterfell-nonprod", "rg-rbg-b2c-winterfell-dev", "rg-rbg-b2c-winterfell-uat")    
}
else {
    Write-Error "Must pass an argument for environment: prod or nonprod"
    exit 1
}

$MaxParallel = 10
$Endpoints = az network private-endpoint list --subscription $SubscriptionNameId -o json | ConvertFrom-Json

Write-Host "Listing all private endpoints"
Write-Host "Subscription: $SubscriptionNameId"
Write-Host "Resource Groups: $ResourceGroups"

$Results = $Endpoints | ForEach-Object -ThrottleLimit $MaxParallel -Parallel {
    if ($using:ResourceGroups -notcontains $_.resourceGroup) {
        return $null
    }

    if ($_.Name.StartsWith("mdb-rbg-b2c")) {
        # Ignore mongo db private endpoints
        return $null
    }

    $nic = az network nic show --ids $_.networkInterfaces[0].id | ConvertFrom-Json

    $nic.ipConfigurations | ForEach-Object {
        [PSCustomObject]@{
            ip   = $_.privateIPAddress
            fqdn = $_.privateLinkConnectionProperties.fqdns[0]
        }
    }
}

# Filter and sort results
$processedResults = ($Results | Where-Object { $_ -ne $null }) | Sort-Object fqdn

if (-not $Check) {
    # Print results to console or file
    if ($OutFile) {
        Write-Host "Writing to $OutFile"
        "# $Environment" | Out-File -FilePath $OutFile -Encoding UTF8
        $processedResults | Format-Table ip, fqdn -AutoSize -HideTableHeaders | Out-File -Append -FilePath $OutFile -Encoding UTF8
    }
    else {
        # Write to console
        $processedResults
    }
}
else {
    # Check all DNS records, get type A or CNAME and check IP is as expected
    
    function Get-PrimaryAOrCNAME {
        param([Parameter(Mandatory)][string]$Name, [string]$Server = "")

        # Prefer dig (fast, explicit timeouts)
        if (Get-Command dig -ErrorAction SilentlyContinue) {
            $args = @()
            if ($Server -and $Server.Trim()) { $args += "@$Server" }
            $args += @("+noall", "+answer", $Name, "A")
            $lines = & dig @args 2>$null

            if (-not $lines) { throw "No response" }

            $primary = $null
            foreach ($line in $lines) {
                if ($line -match '^\s*(\S+)\s+\d+\s+\S+\s+(\S+)\s+(.+?)\s*$') {
                    $type = $matches[2].ToUpper()
                    $data = $matches[3].Trim()
                    if ($type -eq 'CNAME') {
                        $primary = [pscustomobject]@{ Name = $Name; Type = 'CNAME'; Data = $data.TrimEnd('.') }
                        break
                    }
                    elseif (($type -eq 'A') -and -not $primary) {
                        $primary = [pscustomobject]@{ Name = $Name; Type = 'A'; Data = $data }
                    }
                }
            }
            if ($primary) { return $primary }
            throw "No A or CNAME in answer"
        }

        # Fallback: Resolve-DnsName (Windows)
        if (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue) {
            try {
                $a = @{ Name = $Name; Type = 'A'; ErrorAction = 'Stop'; DnsOnly = $true; NoHostsFile = $true }
                if ($Server -and $Server.Trim()) { $a.Server = $Server }
                $resp = Resolve-DnsName @a
            }
            catch {
                throw "DNS query failed: $($_.Exception.Message)"
            }

            $ans = $resp | Where-Object { $_.PSObject.Properties['Section'] -and $_.Section -eq 'Answer' }
            if (-not $ans) { throw "No answers" }

            $cname = $ans | Where-Object { $_.Type -eq 'CNAME' } | Select-Object -First 1
            if ($cname) {
                return [pscustomobject]@{
                    Name = $cname.Name.TrimEnd('.')
                    Type = 'CNAME'
                    Data = $cname.NameHost.TrimEnd('.')
                }
            }

            $aRec = $ans | Where-Object { $_.Type -eq 'A' } | Select-Object -First 1
            if ($aRec) {
                return [pscustomobject]@{
                    Name = $aRec.Name.TrimEnd('.')
                    Type = 'A'
                    Data = $aRec.IPAddress
                }
            }

            throw "No A or CNAME in answer"
        }

        throw "Need dig or Resolve-DnsName"
    }

    # --- One row per FQDN using your $processedResults (expects .fqdn and .ip) ---
    $rows = foreach ($r in $processedResults) {
        $fqdn = "$($r.fqdn)".Trim()
        $ip = "$($r.ip)".Trim()

        if ([string]::IsNullOrWhiteSpace($fqdn) -or [string]::IsNullOrWhiteSpace($ip)) {
            [pscustomobject]@{ FQDN = $fqdn; Type = $null; Data = $null; ExpectedIP = $ip; IpMatch = $false; Status = "Failed"; Reason = "Missing fqdn/ip" }
            continue
        }

        try {
            $p = Get-PrimaryAOrCNAME -Name $fqdn -Server $DnsServer
            $isA = ($p.Type -eq 'A')
            $ipOK = $isA -and ($p.Data -eq $ip)

            [pscustomobject]@{
                FQDN       = $fqdn
                Type       = $p.Type        # A or CNAME
                Data       = $p.Data        # IP if A, target if CNAME
                ExpectedIP = $ip
                IpMatch    = if ($isA) { $ipOK } else { $null }
                Status     = if ($isA) { if ($ipOK) { "OK" } else { "Mismatch" } } else { "" }
                Reason     = if ($isA -and -not $ipOK) { "IP differs" } else { $null }
            }
        }
        catch {
            [pscustomobject]@{ FQDN = $fqdn; Type = $null; Data = $null; ExpectedIP = $ip; IpMatch = $false; Status = "Failed"; Reason = $_.Exception.Message }
        }
    }

    $rows | Format-Table FQDN, Type, Data, ExpectedIP, IpMatch, Status, Reason -AutoSize
}


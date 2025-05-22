# Requires: Az PowerShell Module
# Install with: Install-Module -Name Az -Scope CurrentUser -Force

# Define free-tier thresholds
$freeTierSkus = @("F1", "F0", "Basic", "Shared")
$freeUsageLimits = @{
    "Storage"     = 5 * 1024     # 5GB = 5120MB
    "FunctionApp" = 1000000      # 1 million executions
    "CosmosDB"    = 400          # RU/s
}

$results = @()

# Login
Connect-AzAccount | Out-Null

# Get all subscriptions
$subscriptions = Get-AzSubscription
foreach ($sub in $subscriptions) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null
    Write-Host "Scanning subscription: $($sub.Name)" -ForegroundColor Cyan

    # App Services
    $apps = Get-AzWebApp
    foreach ($app in $apps) {
        $sku = ($app.Sku).Tier
        $isFree = $freeTierSkus -contains $sku
        $appSettings = Get-AzWebApp -ResourceGroupName $app.ResourceGroup -Name $app.Name
        $httpsOnly = $appSettings.HttpsOnly
        $identityEnabled = $app.Identity.Type -ne "None"

        $diag = Get-AzDiagnosticSetting -ResourceId $app.Id -ErrorAction SilentlyContinue
        $diagnosticsEnabled = $diag -ne $null -and $diag.Enabled

        $securityIssues = @()
        if (-not $httpsOnly)        { $securityIssues += "HTTPS Disabled" }
        if (-not $identityEnabled)  { $securityIssues += "Managed Identity Disabled" }
        if (-not $diagnosticsEnabled) { $securityIssues += "Diagnostics Not Enabled" }

        $results += [PSCustomObject]@{
            Subscription     = $sub.Name
            ResourceType     = "App Service"
            ResourceName     = $app.Name
            SKU              = $sku
            IsFreeTier       = $isFree
            UsageWithinLimit = $null
            Active           = $app.State -eq "Running"
            SecurityRisk     = $securityIssues.Count -gt 0
            SecurityFindings = $securityIssues -join "; "
            EstimatedCostUSD = ""
        }
    }

    # Storage Accounts
    $storages = Get-AzStorageAccount
    foreach ($sa in $storages) {
        $context = $sa.Context
        # Approximate usage info – may require Storage context with key
        $usedBytes = 0
        try {
            $blobs = Get-AzStorageContainer -Context $context | ForEach-Object {Get-AzStorageBlob -Container $_.Name -Context $context }
            $usedBytes = ($blobs | Measure-Object -Property Length -Sum).Sum
        } catch {
            Write-Host "Could not retrieve blob size for $($sa.StorageAccountName)" -ForegroundColor Yellow
        }
        $usedMB = $usedBytes / 1MB
        $limitMB = $freeUsageLimits["Storage"]
        $isFree = $freeTierSkus -contains $sa.SkuName

        $publicAccess = $false
        $publicContainers = @()
        try {
            $containers = Get-AzStorageContainer -Context $context
            foreach ($c in $containers) {
                if ($c.PublicAccess -ne "Off") {
                    $publicAccess = $true
                    $publicContainers += $c.Name
                }
            }
        } catch {}

        $networkRules = $sa.NetworkRuleSet
        $firewallEnabled = $networkRules.DefaultAction -eq "Deny"
        $tlsVersionSecure = $sa.MinimumTlsVersion -ge "TLS1_2"

        $securityIssues = @()
        if ($publicAccess)        { $securityIssues += "Public Containers: $($publicContainers -join ", ")" }
        if (-not $firewallEnabled) { $securityIssues += "Firewall Not Configured" }
        if (-not $tlsVersionSecure) { $securityIssues += "TLS < 1.2" }

        $results += [PSCustomObject]@{
            Subscription     = $sub.Name
            ResourceType     = "Storage Account"
            ResourceName     = $sa.StorageAccountName
            SKU              = $sa.SkuName
            IsFreeTier       = $isFree
            UsageWithinLimit = $usedMB -lt $limitMB
            Active           = $usedMB -gt 0
            SecurityRisk     = $securityIssues.Count -gt 0
            SecurityFindings = $securityIssues -join "; "
            EstimatedCostUSD = ""
        }
    }

    # Cosmos DB Accounts - Enumerate by resource group to avoid prompts
$resourceGroups = Get-AzResourceGroup
foreach ($rg in $resourceGroups) {
    $cosmosDbs = Get-AzCosmosDBAccount -ResourceGroupName $rg.ResourceGroupName -ErrorAction SilentlyContinue
    foreach ($db in $cosmosDbs) {
        $isFree = $db.EnableFreeTier
        $publicNetworkAccess = $db.PublicNetworkAccess -ne "Disabled"
        $ipRules = $db.IpRules
        $privateEndpoints = $db.VirtualNetworkRules.Count -gt 0
        $tlsVersionSecure = $true  # Placeholder — no exposed property yet

        $securityIssues = @()
        if ($publicNetworkAccess -and $ipRules.Count -eq 0) { $securityIssues += "Open to Internet" }
        if (-not $privateEndpoints) { $securityIssues += "No Private Endpoint" }

        $results += [PSCustomObject]@{
            Subscription     = $sub.Name
            ResourceType     = "Cosmos DB"
            ResourceName     = $db.Name
            SKU              = "CosmosDB"
            IsFreeTier       = $isFree
            UsageWithinLimit = $null
            Active           = $db.DatabaseAccountOfferType -eq "Standard"
            SecurityRisk     = $securityIssues.Count -gt 0
            SecurityFindings = $securityIssues -join "; "
            EstimatedCostUSD = ""
        }
    }
}

    # Function Apps
    $funcApps = Get-AzFunctionApp
    foreach ($func in $funcApps) {
        $sku = ($func.Sku).Tier
        $isFree = $freeTierSkus -contains $sku
        $httpsOnly = $func.HttpsOnly
        $identityEnabled = $func.Identity.Type -ne "None"

        $diag = Get-AzDiagnosticSetting -ResourceId $func.Id -ErrorAction SilentlyContinue
        $diagnosticsEnabled = $diag -ne $null -and $diag.Enabled

        $securityIssues = @()
        if (-not $httpsOnly)        { $securityIssues += "HTTPS Disabled" }
        if (-not $identityEnabled)  { $securityIssues += "Managed Identity Disabled" }
        if (-not $diagnosticsEnabled) { $securityIssues += "Diagnostics Not Enabled" }

        $results += [PSCustomObject]@{
            Subscription     = $sub.Name
            ResourceType     = "Function App"
            ResourceName     = $func.Name
            SKU              = $sku
            IsFreeTier       = $isFree
            UsageWithinLimit = $null
            Active           = $func.State -eq "Running"
            SecurityRisk     = $securityIssues.Count -gt 0
            SecurityFindings = $securityIssues -join "; "
            EstimatedCostUSD = ""
        }
    }

    # Cost Estimation (without -SubscriptionId)
    $startDate = (Get-Date).ToString("yyyy-MM-01")
    $endDate = (Get-Date).AddMonths(1).ToString("yyyy-MM-01")
    $usageDetails = Get-AzConsumptionUsageDetail -StartDate $startDate -EndDate $endDate -ErrorAction SilentlyContinue

    foreach ($r in $results | Where-Object { $_.Subscription -eq $sub.Name }) {
        $match = $usageDetails | Where-Object { $_.InstanceName -eq $r.ResourceName }
        $r.EstimatedCostUSD = ($match | Measure-Object -Property PretaxCost -Sum).Sum
    }
}

# Output to terminal and CSV
$results | Format-Table -AutoSize

$csvPath = "$env:USERPROFILE\Desktop\Azure_FreeTier_Security_Report.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "`nReport saved to: $csvPath" -ForegroundColor Green

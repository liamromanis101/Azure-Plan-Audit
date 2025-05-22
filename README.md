# Azure-Plan-Audit
Audits Azure plans to detect 'free tier' usage based on Free Tier SKUs, Free Tier usage thresholds, and performs some security checks to confirm free tier usage.

## ⚠️ Security Risks of Free Tier Utilization

| Risk Type                     | Description                                                                                     | Risk Level |
|------------------------------|-------------------------------------------------------------------------------------------------|------------|
| **Overlooked Resources**     | Free-tier services may fly under the radar due to no billing alerts, making them easy to forget. | High       |
| **Unsecured Public Access**  | Developers often deploy test apps or storage with public endpoints, sometimes left exposed.     | High       |
| **Stale/Test Data**          | Free resources are often used for test data, which may still contain real credentials or PII.   | Medium     |
| **No Logging/Monitoring**    | Users may skip enabling diagnostics to stay within free limits, making incident response harder. | High       |
| **Abuse or Takeover Risk**   | Attackers can scan for weakly secured free-tier resources (e.g., web apps, APIs).               | High       |
| **Limited Security Features**| Some services offer reduced security in free tiers (e.g., no IP filtering, TLS options).        | Medium     |
| **Shared Credentials**       | Quick prototyping often leads to use of shared or hardcoded secrets in free-tier resources.     | Medium     |

## ✅ How the Script Confirms Free Tier Usage

| Step                           | Description                                                                                     |
|--------------------------------|-------------------------------------------------------------------------------------------------|
| **Azure Login**                | Authenticates the user with Azure and retrieves all subscriptions.                             |
| **Resource Enumeration**       | Scans each subscription for known services that may offer free-tier SKUs or usage-based tiers. |
| **SKU-Based Detection**        | Compares the resource's SKU against known free-tier SKUs (e.g., `F1`, `F0`).                    |
| **Usage-Based Detection**      | For services like Storage, Functions, and Cosmos DB, checks usage levels against free limits.  |
| **In-Use Check**               | Attempts to determine whether each resource is currently active or holding data.               |
| **Security Audit**             | Flags potential risks like public access or missing diagnostic logging.                        |
| **Results Table**              | Outputs a formatted summary table of free-tier status, usage, and security concerns.           |
| **CSV Export**                 | Saves the report as a `.csv` file for further analysis or tracking.                            |

## 🚀 Usage Instructions

| Step                            | Description                                                                                   |
|---------------------------------|-----------------------------------------------------------------------------------------------|
| **1. Clone or Copy Script**     | Save the PowerShell script to your local system (e.g., `Check-FreeTierUsage.ps1`).            |
| **2. Open PowerShell**          | Run PowerShell as your current user (admin rights not strictly necessary).                   |
| **3. Install Az Module**        | Run `Install-Module -Name Az -Scope CurrentUser` if you haven't already.                     |
| **4. Run the Script**           | Execute with: `.\Check-FreeTierUsage.ps1`                                                     |
| **5. Authenticate to Azure**    | You'll be prompted to log in if you're not already authenticated.                            |
| **6. Review the Report**        | The script will print a table and export a CSV report (`AzureFreeTierSecurityReport.csv`).    |

## 📊 Sample Output

| SubscriptionName | ResourceGroup   | ResourceName      | ResourceType                         | Sku   | IsFreeTier | IsInUse | UsageNote                      | SecurityRiskNote                    |
|------------------|------------------|--------------------|---------------------------------------|-------|------------|---------|--------------------------------|--------------------------------------|
| Contoso-Prod     | AppServicesRG    | contoso-webapp     | Microsoft.Web/sites                   | F1    | True       | True    | Running                        | ⚠️ No diagnostic logging             |
| Contoso-Dev      | StorageRG        | contosostorage     | Microsoft.Storage/storageAccounts     | LRS   | True       | True    | Used: 3.12 GB                  | ⚠️ Public access enabled; ⚠️ No diagnostic logging |
| Marketing        | AnalyticsRG      | ai-cognitive-api   | Microsoft.CognitiveServices/accounts  | F0    | True       | True    |                                |                                      |
| Contoso-Prod     | CosmosRG         | cosmos-db-account  | Microsoft.DocumentDB/databaseAccounts|       | True       | True    | Free tier enabled: True        | ⚠️ No diagnostic logging             |
| Sandbox          | FuncAppsRG       | test-func-app      | Microsoft.Web/functions               |       | True       | True    | Estimated executions: 450000   |                                      |




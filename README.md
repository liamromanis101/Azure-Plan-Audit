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


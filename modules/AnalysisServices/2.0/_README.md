# Analysis Services

This module deploys Analysis Services. 

https://docs.microsoft.com/en-us/azure/templates/microsoft.analysisservices/allversions


## Resources

The following Resources are deployed.

+ **Analysis Services**
+ **DiagnosticSettings**


## Parameters

+ **asServerName** - The name of the Azure Analysis Services server to create
+ **location** - Location for resource
+ **serverLocation** - Location of the Azure Analysis Services server. Availablity B1, B2, S0, S1, S2, S4, S8, S9, D1
+ **skuName** - The sku name of the Azure Analysis Services server to create. Choose from: B1, B2, S0, S1, S2, S4, S8, S9, D1 - Southeast Asia
+ **capacity** - The total number of query replica scale-out instances
+ **firewallSettings** - The inbound firewall rules to define on the server. If not specified, firewall is disabled
+ **diagnosticStorageAccountName** - Storage Account for diagnostics
+ **diagnosticStorageAccountRG** - Storage Account for diagnostics
+ **logAnalyticsWorkspaceResourceGroup** - Name of the Resource Group housing the Log Analytics workspace
+ **logAnalyticsWorkspaceName** - Name of the Log Analytics workspace used for diagnostic log integration
+ **logsRetentionInDays** - Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely


## Outputs

  There is no Outputs in this Module


## Scripts

There is no Scripts in this Module

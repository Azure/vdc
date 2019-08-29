 # Analysis Services

This module deploys Analysis Services. 


## Resources

The following Resources are deployed.

+ **Microsoft.AnalysisServices/servers**
+ **Microsoft.AnalysisServices/servers/providers/diagnosticsettings**


## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `serverName` || **Required** The name of the Azure Analysis Services server to create
| `Location` || **Optional** Location of the Azure Analysis Services server.
| `skuName` | S0 | **Optional** The sku name of the Azure Analysis Services server to create.
| `skuCapacity` | 1 | **Optional** The total number of query replica scale-out instances
| `firewallSettings` | AllowFromAll | **Optional** The inbound firewall rules to define on the server. If not specified, firewall is disabled
| `diagnosticStorageAccountId` || **Required** Resource identifier of the Diagnostic Storage Account
| `logAnalyticsWorkspaceId` || **Required** Resource identifier of Log Analytics Workspace
| `logsRetentionInDays` | 30 |**Optional** Specifies the number of days that logs will be kept for, a value of 0 will retain data indefinitely
| `cuaId` || **Optional** Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagEnvironment` || **Optional** The name of the Environment
| `tagProject` || **Optional** The name of the project
| `tagApplication` || **Optional** The name of the application
| `tagOwner` || **Optional** The business owner for the application
| `tagOwnerEmail` || **Optional** The Email address of the business owner for the application


## Outputs

| Output Name | Description |
| :-          | :-          |
| `analysisServicesName` |  Analysis Services Name output parameter
| `analysisServicesResourceId` | Analysis Services ResourceId output parameter
| `analysisServicesResourceGroup` | Analysis Services ResourceGroup output parameter


## Scripts

+ There is no Scripts for this Module


## Considerations

+ There is no deployment considerations for this Module


## Additional resources

[Microsoft Analysis Services template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.analysisservices/allversions)
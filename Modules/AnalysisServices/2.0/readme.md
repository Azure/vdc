# Analysis Services

This module deploys Analysis Services.

## Resources

The following Resources are deployed.

+ **Microsoft.AnalysisServices/servers**
+ **Microsoft.AnalysisServices/servers/providers/diagnosticsettings**

## Parameters

| Parameter Name | Default Value | Required | Description |
| :-             | :-            | :-       |:-           |
| `serverName` || **Required** | The name of the Azure Analysis Services server to create
| `location` || **Optional** | Location for all Resources
| `skuName` | S0 | **Optional** | The sku name of the Azure Analysis Services server to create
| `skuCapacity` | 1 | **Optional** | The total number of query replica scale-out instances
| `firewallSettings` | AllowFromAll | **Optional** | The inbound firewall rules to define on the server. If not specified, firewall is disabled
| `diagnosticStorageAccountId` || **Required** | Resource identifier of the Diagnostic Storage Account
| `logAnalyticsWorkspaceId` || **Required** | Resource identifier of Log Analytics Workspace
| `logsRetentionInDays` | 30 |**Optional** | Specifies the number of days that logs will be kept for, a value of 0 will retain data indefinitely
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagValues` || **Optional** | Optional. Azure Resource Tags object

## Outputs

| Output Name | Description |
| :-          | :-          |
| `analysisServicesName` |  Analysis Services Name output parameter
| `analysisServicesResourceId` | Analysis Services ResourceId output parameter
| `analysisServicesResourceGroup` | Analysis Services ResourceGroup output parameter

## Scripts

+ There is no deployment considerations for this Module.

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

+ [Microsoft Analysis Services template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.analysisservices/allversions)
+ [Microsoft Analysis Services diagnostic settings reference](https://azure.microsoft.com/en-us/blog/azure-analysis-services-integration-with-azure-diagnostic-logs/)


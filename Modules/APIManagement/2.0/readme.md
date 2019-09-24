# Api Management

This module deploys Api Management. 

## Resources

The following Resources are deployed.

+ **Microsoft.ApiManagement/service**
+ **Microsoft.ApiManagement/service/providers/diagnosticsettings**

## Parameters

| Parameter Name | Default Value | Required | Description |
| :-             | :-            | :-       |:-           |
| `apiManagementServiceName` || **Required** | The name of the of the Api Management Service
| `publisherEmail` || **Required** | The email address of the owner of the service
| `publisherName` || **Required** | The name of the owner of the service
| `notificationSenderEmail` || **Optional** | The notification sender email address for the service
| `sku` | Developer | **Optional** | The pricing tier of this Api Management service
| `skuCount` | 1 | **Optional** | The instance size of this Api Management service
| `location` | resourceGroup().location | **Optional** | Location for all Resources"
| `diagnosticStorageAccountId` || **Required** | Resource identifier of the Diagnostic Storage Account
| `logAnalyticsWorkspaceId` || **Required** | Resource identifier of Log Analytics Workspace
| `logsRetentionInDays` | 30 | **Optional** | Specifies the number of days that logs will be kept for, a value of 0 will retain data indefinitely
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagValues` || **Optional** | Optional. Azure Resource Tags object

## Outputs

| Output Name | Description |
| :-          | :-          |
| `apimServiceName` | Api Management Service Name output parameter
| `apimServiceResourceId` | Api Management Service ResourceId output parameter
| `apimServiceResourceGroup` | Api Management Service ResourceGroup output parameter

## Scripts

+ There is no deployment considerations for this Module.

## Considerations

+ There is no deployment considerations for this Module.

## Additional resources

+ [Microsoft Api Management template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/allversions)
+ [Microsoft Api Management diagnostic settings reference](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-use-azure-monitor#diagnostic-logs)

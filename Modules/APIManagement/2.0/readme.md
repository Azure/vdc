# API Management

This module deploys API Management. 


## Resources

The following Resources are deployed.

+ **Microsoft.ApiManagement/service**
+ **Microsoft.ApiManagement/service/providers/diagnosticsettings**


## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `apiManagementServiceName` || **Required** The name of the of the API Management Service
| `publisherEmail` || **Required** The email address of the owner of the service
| `publisherName` || **Required** The name of the owner of the service
| `sku` | Developer | **Optional** The pricing tier of this API Management service
| `skuCount` | 1 | **Optional** The instance size of this API Management service
| `location` | resourceGroup().location | **Optional** Location for all resources
| `diagnosticStorageAccountId` || **Required** Resource identifier of the Diagnostic Storage Account
| `logAnalyticsWorkspaceId` || **Required** Resource identifier of Log Analytics Workspace
| `logsRetentionInDays` | 30 | **Optional** Specifies the number of days that logs will be kept for, a value of 0 will retain data indefinitely
| `cuaId` || **Optional** Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagEnvironment` || **Optional** The name of the Environment
| `tagProject` || **Optional** The name of the project
| `tagApplication` || **Optional** The name of the application
| `tagOwner` || **Optional** The business owner for the application
| `tagOwnerEmail` || **Optional** The Email address of the business owner for the application


## Outputs

| Output Name | Description |
| :-          | :-          |
| `apimServiceName` | API Management Service Name output parameter
| `apimServiceResourceId` | API Management Service ResourceId output parameter
| `apimServiceResourceGroup` | API Management Service ResourceGroup output parameter


## Scripts

+ There is no Scripts for this Module


## Considerations

+ There is no deployment considerations for this Module.


## Additional resources

[Microsoft API Management template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.apimanagement/allversions)
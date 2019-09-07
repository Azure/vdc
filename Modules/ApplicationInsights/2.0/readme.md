# Application Insights

This module deploys Application Insights. 

## Resources

The following Resources are deployed.

+ **Microsoft.Insights/components** 
+ **Microsoft.Storage/storageAccount**


## Parameters

| Parameter Name | Default Value | Required | Description |
| :-             | :-            | :-       |:-           |
| `appInsightsName` || **Required** | Name of the Application Insights
| `appInsightsType` | web | **Optional** | Application type
| `location` | resourceGroup().location | **Optional** | Location for all Resources
| `storageAccountName` || **Required** | Storage Account Name
| `storageAccountType` | Standard_GRS | **Optional** | Storage Account sku type
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagEnvironment` || **Optional** | The name of the Environment
| `tagProject` || **Optional** | The name of the project
| `tagApplication` || **Optional** | The name of the application
| `tagOwner` || **Optional** | The business owner for the application
| `tagOwnerEmail` || **Optional** | The Email address of the business owner for the application

## Outputs

| Output Name | Description |
| :-          | :-          |
| `appInsightsName` | Application Insights Resource Name
| `appInsightsResourceId` | Application Insights Resource Id
| `appInsightsResourceGroup` | Application Insights ResourceGroup
| `appInsightsKey` | Application Insights Resource Instrumentation Key
| `appInsightsAppId` | Application Insights Paalication Id
| `appInsightsStorageAccountName` | Application Insights Logging Storage Account Name

## Scripts

| Output Name | Description |
| :-          | :-          |
| `application.insights.akv.secrects.ps1` |  Set Application Insights KeyVault Secrets Automation Script
| `application.insights.continuous.export.ps1` |  Configures Application Insights Continuous Export Configuration

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

[Microsoft Insights template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/allversions)
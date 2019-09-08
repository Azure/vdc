# Machine Learning Services

This module deploys a Machine Learning Services Workspace. 

## Resources

The following Resources are deployed.

+ **Microsoft.MachineLearningServices/workspaces** 
+ **Microsoft.Storage/storageAccounts** 

## Parameters

| Parameter Name | Default Value | Required | Description |
| :-             | :-            | :-       |:-           |
| `workspaceName` || **Required** | T1he name of the Azure Machine Learning service workspace
| `storageAccountName` || **Required** | Storage Account Name
| `storageAccountSku` | Standard_GRS | **Optional** | Storage Account sku type
| `keyVaultResourceId` || **Required** | Resource identifier of the KeyVault
| `appInsightsResourceId` || **Required** | Resource identifier of the Application Insights
| `location` | resourceGroup().location | **Optional** | Location for all resources
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagEnvironment` || **Optional** | The name of the Environment
| `tagProject` || **Optional** | The name of the project
| `tagApplication` || **Optional** | The name of the application
| `tagOwner` || **Optional** | The business owner for the application
| `tagOwnerEmail` || **Optional** | The Email address of the business owner for the application

## Outputs
| Output Name | Description |
| :-          | :-          |
| `machinelearningName` |  Machine Learning Services Name output parameter
| `machinelearningResourceId` | Machine Learning Services ResourceId output parameter
| `machinelearningResourceGroup` | Machine Learning Services ResourceGroup output parameter

## Scripts

| Script Name | Description |
| :-          | :-          |
| `machine.learning.akv.secrects.ps1` | Set Machine Learning Services KeyVault Secrets Automation Script

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

[Microsoft Machine Learning Services template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/allversions)
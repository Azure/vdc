# Machine Learning

This module deploys a Machine Learning Workspace Plans. 

## Resources

The following Resources are deployed.

+ **Microsoft.MachineLearning/workspaces** 
+ **Microsoft.MachineLearning/commitmentPlans**
+ **Microsoft.Storage/storageAccounts** 

## Parameters

| Parameter Name | Default Value | Required | Description |
| :-             | :-            | :-       |:-           |
| `workspaceName` || **Required** | T1he name of the Azure Machine Learning service workspace
| `planName` || **Required** | The name of the Machine Learning Plan
| `ownerEmail` || **Required** | The Email address of the business owner for the Machine Learning Plan
| `skuName` || **Optional** | Machine Learning Plan sku name
| `skuTier` || **Optional** | Machine Learning Plan account tier
| `skuCapacity` || **Optional** | Machine Learning Plan scale-out capacity of the resource
| `location` | resourceGroup().location | **Optional** | Location for all resources
| `storageAccountName` || **Required** | Storage Account Name
| `storageAccountSku` | Standard_GRS | **Optional** | Storage Account sku type
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagEnvironment` || **Optional** | The name of the Environment
| `tagProject` || **Optional** | The name of the project
| `tagApplication` || **Optional** | The name of the application
| `tagOwner` || **Optional** | The business owner for the application
| `tagOwnerEmail` || **Optional** | The Email address of the business owner for the application

## Outputs
| Output Name | Description |
| :-          | :-          |
| `machinelearningName` |  Machine Learning Name output parameter
| `machinelearningResourceId` | Machine Learning ResourceId output parameter
| `machinelearningResourceGroup` | Machine Learning ResourceGroup output parameter

## Scripts

| Script Name | Description |
| :-          | :-          |
| `machine.learning.akv.secrects.ps1` | Set Machine Learning KeyVault Secrets Automation Script

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

[Microsoft Machine Learning template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.machinelearning/allversions)
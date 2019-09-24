# Machine Learning Services

This module deploys a Machine Learning Services Workspace. 

## Resources

The following Resources are deployed.

+ **Microsoft.MachineLearningServices/workspaces** 

## Parameters

| Parameter Name | Default Value | Required | Description |
| :-             | :-            | :-       |:-           |
| `workspaceName` || **Required** | T1he name of the Azure Machine Learning service workspace
| `storageAccountResourceId` || **Required** | Resource identifier of the Storage Account
| `keyVaultResourceId` || **Required** | Resource identifier of the KeyVault
| `appInsightsResourceId` || **Required** | Resource identifier of the Application Insights
| `location` | resourceGroup().location | **Optional** | Location for all resources
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagValues` || **Optional** | Optional. Azure Resource Tags object

## Outputs
| Output Name | Description |
| :-          | :-          |
| `machinelearningName` |  Machine Learning Services Name output parameter
| `machinelearningResourceId` | Machine Learning Services ResourceId output parameter
| `machinelearningResourceGroup` | Machine Learning Services ResourceGroup output parameter

## Scripts

+ There is no Scripts for this Module

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

+ [Microsoft Machine Learning Services template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.machinelearningservices/allversions)
# Machine Learning

This module deploys a Machine Learning Workspace Plans. 

## Resources

The following Resources are deployed.

+ **Microsoft.MachineLearning/workspaces** 
+ **Microsoft.MachineLearning/commitmentPlans**

## Parameters

| Parameter Name | Default Value | Required | Description |
| :-             | :-            | :-       |:-           |
| `workspaceName` || **Required** | T1he name of the Azure Machine Learning service workspace
| `planName` || **Required** | The name of the Machine Learning Plan
| `ownerEmail` || **Required** | The Email address of the business owner for the Machine Learning Plan
| `skuName` || **Optional** | Machine Learning Plan sku name
| `skuTier` || **Optional** | Machine Learning Plan account tier
| `skuCapacity` || **Optional** | Machine Learning Plan scale-out capacity of the resource
| `storageAccountResourceId` || **Required** | Resource identifier of the Storage Account
| `location` | resourceGroup().location | **Optional** | Location for all resources
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagValues` || **Optional** | Optional. Azure Resource Tags object

## Outputs
| Output Name | Description |
| :-          | :-          |
| `machinelearningName` |  Machine Learning Name output parameter
| `machinelearningResourceId` | Machine Learning ResourceId output parameter
| `machinelearningResourceGroup` | Machine Learning ResourceGroup output parameter

## Scripts

+ There is no Scripts for this Module

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

+ [Microsoft Machine Learning template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.machinelearning/allversions)
# Cognitve Services

This module deploys Cognitve Services Translation API.

## Resources

The following Resources are deployed.

+ **Microsoft.CognitiveServices/accounts**

## Parameters

| Parameter Name | Default Value | Required | Description |
| :-             | :-            | :-       |:-           |
| `accountName` || **Required** |The name of Text Translation API account
| `sku` | S0| **Optional** | sku for Text Translation API
| `location` || **Optional** | Location of the Azure Analysis Services server
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagEnvironment` || **Optional** | The name of the Environment
| `tagProject` || **Optional** | The name of the project
| `tagApplication` || **Optional** | The name of the application
| `tagOwner` || **Optional** | The business owner for the application
| `tagOwnerEmail` || **Optional** | The Email address of the business owner for the application

## Outputs

| Output Name | Description |
| :-          | :-          |
| `cognitiveServicesName` |  Cognitive Services Name output parameter
| `cognitiveServicesResourceId` | Cognitive Services ResourceId output parameter
| `cognitiveServicesResourceGroup` | Cognitive Services ResourceGroup output parameter

## Scripts

| Script Name | Description |
| :-          | :-          |
| `cognitive.services.akv.secrects.ps1` | Set Cognitive Services KeyVault Secrets Automation Script

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

[Microsoft Cognitve Services template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/allversions)

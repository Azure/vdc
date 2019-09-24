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
| `location` || **Optional** | Location for all Resources
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagValues` || **Optional** | Optional. Azure Resource Tags object

## Outputs

| Output Name | Description |
| :-          | :-          |
| `cognitiveServicesName` |  Cognitive Services Name output parameter
| `cognitiveServicesResourceId` | Cognitive Services ResourceId output parameter
| `cognitiveServicesResourceGroup` | Cognitive Services ResourceGroup output parameter

## Scripts

+ There is no Scripts for this Module

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

+ [Microsoft Cognitve Services template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/allversions)

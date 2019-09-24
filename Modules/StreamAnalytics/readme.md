# Stream Analytics

This module deploys a Standard Stream Analytics Job

## Resources

The following Resources are deployed.

+ **Microsoft.StreamAnalytics/StreamingJobs**

## Parameters

| Parameter Name | Default Value | Required | Description |
| :-             | :-            | :-       |:-           |
| `streamAnalyticsJobName` || **Required** | Stream Analytics Job Name
| `numberOfStreamingUnits` | 1 | **Optional** | Number of Streaming Units
| `location` | resourceGroup().location | **Optional** | Location for all Resources
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagValues` || **Optional** | Optional. Azure Resource Tags object

## Outputs

| Output Name | Description |
| :-          | :-          |
| `streamAnalyticsName` |  Stream Analytics Name output parameter
| `streamAnalyticsResourceId` | Stream Analytics ResourceId output parameter
| `streamAnalyticsResourceGroup` | Stream Analytics ResourceGroup output parameter

## Scripts

+ There is no Scripts for this Module

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

+ [Microsoft Stream Analytics template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.streamanalytics/allversions)

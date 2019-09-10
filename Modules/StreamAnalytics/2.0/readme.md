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
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagEnvironment` || **Optional** | The name of the Environment
| `tagProject` || **Optional** | The name of the project
| `tagApplication` || **Optional** | The name of the application
| `tagOwner` || **Optional** | The business owner for the application
| `tagOwnerEmail` || **Optional** | The Email address of the business owner for the application

## Outputs

| Output Name | Description |
| :-          | :-          |
| `streamAnalyticsName` |  Stream Analytics Name output parameter
| `streamAnalyticsResourceId` | Stream Analytics ResourceId output parameter
| `streamAnalyticsResourceGroup` | Stream Analytics ResourceGroup output parameter

## Scripts

| Script Name | Description |
| :-          | :-          |
| `stream.analytics.akv.secrects.ps1` | Set Stream Analytics KeyVault Secrets Automation Script

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

[Microsoft Stream Analytics template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.streamanalytics/allversions)

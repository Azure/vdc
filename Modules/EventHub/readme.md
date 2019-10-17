# EventHub Namespace

This module deploys EventHub Namespace. 

## Resources

The following Resources are deployed.

+ **Microsoft.EventHub/namespaces**
+ **Microsoft.EventHub/namespaces/providers/diagnosticSettings**
+ **Microsoft.EventHub/namespaces/AuthorizationRules**
+ **Microsoft.EventHub/namespaces/eventhubs**
+ **Microsoft.EventHub/namespaces/eventhubs/consumergroups**

## Parameters

| Parameter Name | Default Value | Required | Description |
| :-             | :-            | :-       |:-           |
| `namespaceName` || **Required** | The name of the EventHub namespace
| `eventHubName` || **Required** | The name of the EventHub
| `messageRetentionInDays` | 1 | **Optional** | How long to retain the data in EventHub
| `partitionCount` | 4 | **Optional** | Number of partitions chosen 
| `skuName` || **Optional** | EventHub Plan sku name
| `skuTier` || **Optional** | EventHub Plan account tier
| `skuCapacity` || **Optional** | EventHub Plan scale-out capacity of the resource
| `location` | resourceGroup().location | **Optional** | Location for all Resources
| `diagnosticStorageAccountId` || **Required** | Resource identifier of the Diagnostic Storage Account
| `workspaceId` || **Required** | Required. Resource identifier of Log Analytics.
| `logsRetentionInDays` | 30 |**Optional** | Specifies the number of days that logs will be kept for, a value of 0 will retain data indefinitely
| `cuaId` || **Optional** | Customer Usage Attribution Id (GUID). This GUID must be previously registered
| `tagValues` || **Optional** | Optional. Azure Resource Tags object

## Outputs

| Output Name | Description |
| :-          | :-          |
| `namespaceName` |  EventHub Namespace Name output parameter
| `namespaceResourceId` | EventHub Namespace ResourceId output parameter
| `namespaceResourceGroup` | EventHub Namespace ResourceGroup output parameter
| `namespaceConnectionString` | EventHub Namespace Connection String
| `sharedAccessPolicyPrimaryKey` | EventHub Namespace Shared Access Policy Primary Key 

## Scripts

+ There is no Scripts for this Module

## Considerations

+ There is no deployment considerations for this Module

## Additional resources

+ [Microsoft EventHub template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.eventhub/allversions)

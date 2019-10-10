# Kusto Database

This module deploys a Kusto Database (Azure Data Explorer Database).


## Deployed Resources

The following resources are deployed as part of this code block:

+ N/A

## Parameters

**Kusto Database**

| Parameter Name    | Default Value | Description
| :-                | :-            | :-
| `clusterName` |     | Required. The name of the Kusto Cluster.
| `location` |  resourceGroup().location   | Optional. Location for all Resources.
| `databaseName` |     | Required. The name of the Kusto Database to create.
| `softDeletePeriod` |     | Optional. The time the data should be kept before it stops being accessible to queries in TimeSpan.
| `hotCachePeriod` |     | Optional. The time the data should be kept in cache for fast queries in TimeSpan.
| `databaseSize` |     | Optional. The database size - the total size of compressed data and index in bytes.

## Additional resources

- N/A
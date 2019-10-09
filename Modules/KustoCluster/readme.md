# Kusto Cluster

This module deploys a Kusto Cluster (Azure Data Explorer).


## Deployed Resources

The following resources are deployed as part of this code block:

+ **Azure Data Explorer Cluster**

## Parameters

**Kusto Cluster**

| Parameter Name    | Default Value | Description
| :-                | :-            | :-
| `clusterName` |     | Required. The name of the Kusto Cluster.
| `location` |  resourceGroup().location   | Optional. Location for all Resources.
| `skuName` |     | Required. Kusto Cluster sku name.
| `skuTier` |  Standard   | Required. SKU tier.
| `skuCapacity` |  2   | Optional. The number of instances of the cluster.
| `trustedExternalTenants` |  []   | Required. The cluster's external tenants in the form [{"value": TENANT ID}]
| `zones` |  []   | Optional. The availability zones of the cluster.
| `enableDiskEncryption` |  true   | Optional. A boolean value that indicates if the cluster's disks are encrypted.
| `enableStreamingIngest` |  false   | Optional. A boolean value that indicates if the streaming ingest is enabled.
| `optimizedAutoscaleVersion` |  1   | Required. The version of the template defined, for instance 1.
| `optimizedAutoscaleIsEnabled` |  false   | Required. A boolean value that indicate if the optimized autoscale feature is enabled or not.
| `optimizedAutoscaleMinimum` |  1   | Required. Minimum allowed instances count.
| `optimizedAutoscaleMaximum` |  1   | Required. Maximum allowed instances count.
| `subnetId` |     | Optional. The subnet resource id.
| `enginePublicIpId` |     | Optional. Engine service's public IP address resource id.
| `dataManagementPublicIpId` |     | Optional. Data management's service public IP address resource id.

## Additional resources

- [ARM Template schema for Kusto Database](https://docs.microsoft.com/en-us/azure/templates/microsoft.kusto/2019-05-15/clusters/databases)

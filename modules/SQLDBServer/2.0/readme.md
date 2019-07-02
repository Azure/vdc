# SQL Database Server

This module deploys the logical SQL server where SQL databases can land on.


## Deployed Resources

The following resources are deployed as part of this code block:

+ **SQL Server**

On the SQL server the [Advanced Data Security](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-advanced-data-security) capabilities and the vulnerability assessments are by default enabled.

## Deployment prerequisites
Vulnerability Assessment is a scanning service built into the Azure SQL Database service. When this option is enabled, the scan results are stored in a storage account. 
It is enabled by default for this deployment of the SQL server. The name of an existing storage account is required to deploy an Azure SQL with this option.

## Parameters

**SQL Server**

| Parameter Name    | Default Value | Description
| :-                | :-            | :-
| `administratorLogin` |     | Required. Administrator username for the server. Can only be specified when the server is being created (and is required for creation).
| `administratorLoginPassword` |     | Required. The administrator login password (required for managed instance creation).
| `serverName` |     | Required. The name of the SQL server to be created.
| `location` |  resourceGroup().location   | Optional. Azure region where the SQL managed instance will be deployed.
| `allowAzureIps` |  true   | Optional. Whether the database is accessible by the Azure services.
| `diagnosticStorageAccountPrimaryBlobEndpoint` |     | Required. The primary blob endpoint of the storage account where the vulnerability assesments scan results will be stored.
| `diagnosticStorageAccountAccessKey` |     | Required. The access key of the storage account where the vulnerability assesments scan results will be stored.
| `virtualNetworkList` |     | Optional.List of service endpoints to be enabled for the server.|

## Additional resources

- [Introduction to Azure SQL](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-single-index)
- [ARM Template schema for SQL Database](https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/2017-10-01-preview/servers/databases)
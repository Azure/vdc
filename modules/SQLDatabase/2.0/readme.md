# SQL Database

This module deploys a SQL database on an existing SQL server. 


## Deployed Resources

The following resources are deployed as part of this code block:

+ **SQL Database**

On the SQL database Transparent Data Encryption is enabled by default.

## Deployment prerequisites
The name of an existing SQL Server is required to deploy a database on it.

## Parameters

**SQL Database**

| Parameter Name    | Default Value | Description
| :-                | :-            | :-
| `location` |  resourceGroup().location   | Optional. Azure region where the SQL managed instance will be deployed.
| `databaseName` |     | Required. The name of the SQL database.
| `skuName` | GP_Gen5_2  | Optional. The name of the SKU.
| `skuTier` | GeneralPurpose | Optional. The tier of the SKU.
| `collation` | SQL_Latin1_General_CP1_CI_AS | Optional. The database collation for governing the proper use of characters
| `maxSizeBytes` |  34359738368   | Optional. The max size of the database expressed in bytes.
| `serverName` |     | Required. The name of the SQL server on which the database will be created.
| `sampleName` |     | Optional. Indicates the name of the sample schema to apply when creating the database.
| `zoneRedundant` |  false   | Optional. Whether or not this database is zone redundant, which means the replicas of this database will be spread across multiple availability zones.
| `licenseType` | LicenseIncluded | Optional. The license type. Possible values are 'LicenseIncluded' and 'BasePrice'.
| `readScale` | Disabled    | Optional. If the database is a geo-secondary, readScale indicates whether read-only connections are allowed to this database or not. Enabled or Disabled.
| `readReplicaCount` | 0    | Optional. Number of replicas to be created.
| `minCapacity` |     | Optional.
| `autoPauseDelay` |     | Optional. Defines the period of time the database must be inactive before it is automatically paused.


## Additional resources

- [Introduction to Azure SQL](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-single-index)
- [ARM Template schema for SQL Database](https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/2017-10-01-preview/servers/databases)
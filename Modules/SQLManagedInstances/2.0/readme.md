# SQL Managed Instance

This template deploys an SQL Managed Instance. 

## Deployed Resources

The following resources are deployed as part of this code block.

+ **SQL Managed Instance**


## Deployment prerequisites
SQL Managed Instance is deployed on a virtual network. This network is required to satisfy the requirements explained [here](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-connectivity-architecture#network-requirements).

## Parameters

| Parameter Name    | Default Value | Description
| :-                | :-            | :-
| `adminUsername` |     | Required. Administrator username for the managed instance. Can only be specified when the managed instance is being created (and is required for creation).
| `adminPassword` |     | Required. The administrator login password (required for managed instance creation).
| `location` |     | Required. Azure region where the SQL managed instance will be deployed.
| `managedInstanceName` |     | Required. The name of the SQL managed instance.
| `vNetResourceGroup` |     | Required. The name of the resource group where the VNet resides.
| `vNetName` |     | Required. The name the VNet on which the SQL managed instance will be placed.
| `subnetName` |     | Required. The name the subnet on which the SQL managed instance will be placed.
| `skuName` | GP_Gen4      | Optional. The managed instance SKU.
| `skuEdition` | GeneralPurpose | Optional. The managed instance SKU edition.
| `storageSizeInGB` | 32 | Optional. The maximum storage size in GB.
| `vCores` | 16 | Optional. The number of vCores.
| `licenseType` | LicenseIncluded | Optional. The license type. Possible values are 'LicenseIncluded' and 'BasePrice'.
| `hardwareFamily` | Gen4 | Optional. Hardware generation for the SQL managed instance to be deployed. 
| `dnsZonePartner` |  | Optional. The resource id of another managed instance whose DNS zone this managed instance will share after creation.
| `collation` | SQL_Latin1_General_CP1_CI_AS | Optional. The database collation for governing the proper use of characters
| `proxyOverride` | | Optional. The connection type used for connecting to the instance.
| `publicDataEndpointEnabled` | false | Optional. Whether or not the public data endpoint is enabled.
| `timezoneId` | UTC | Optional. The time zone setting.

## Additional resources

- [Introduction to Azure SQL Managed Instance](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-index)
- [ARM Template schema for SQL Managed Instance](https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/2015-05-01-preview/managedinstances)

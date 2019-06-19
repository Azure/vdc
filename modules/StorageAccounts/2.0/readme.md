# StorageAccount

This module is used to deploy an Azure Storage Account, with resource lock and the ability to deploy 1 or more Blob Containers. Optional ACLS can also be configured on the Storage Account too.

The default parameter values are based on the needs of deploying a diagnostic storage account.

## Resources

- Microsoft.Storage/storageAccounts
- Microsoft.Storage/storageAccounts/providers/locks
- Microsoft.Storage/storageAccounts/blobServices/containers

## Parameters

| Parameter Name    | Default Value | Description
| :-                | :-            | :-
| `storageAccountName` |       | Required. Name of the Storage account.
| `storageAccountKind` | `StorageV2` | Optional. Type of Storage Account to create.
| `storageAccountSku` | `Standard_GRS`| Optional. Storage Account Sku Name.
| `storageAccountAccessTier` | `Hot` | Optional. Storage Account Access Tier.
| `lockForDeletion` | `true` | Optional. Switch to lock storage from deletion.
| `utcYear` | `[utcNow('yyyy')]` | Optional. Year data used to generate a SAS token. Default is the current year.
| `vNetId` |  | Optional. Virtual Network Identifier used to create a service endpoint.
| `networkAcls` |  | Optional. Network ACLs, this value contains IPs to whitelist and/or Subnet information.
| `blobContainers` | | Optional. Blob containers to create.

### Parameter Usage: `blobContainers`

The `blobContainer` parameter accepts a JSON Array of object with "name" property in each to specify the name of the Blob Containers to create.

Here's an example of specifying a single Blob Container named "one":

```json
[{"name": "one"}]
```

Here's an example of specifying multiple Blob Containers to create:

```json
[{"name": "one"}, {"name": "two"}]
```

## Outputs

| Output Name | Description |
| :- | :- |
| `storageAccountResourceId` | The Resource id of the Storage Account.
| `storageAccountName` | The Name of the Storage Account.
| `storageAccountResourceGroup` | The name of the Resource Group the Storage Account was created in.
| `storageAccountSasToken` | The SAS Token for the Storage Account.<br/>The SAS Token generated is set to expire 100 years from the value of the `utcYear` parameter.
| `storageAccountAccessKey` | The Access Key for the Storage Account.

## Considerations

This is a generic module for deploying a Storage Account. Any customization for different storage needs (such as a diagnostic or other storage account) need to be done through the Archetype.

## Additional resources

- [Introduction to Azure Storage](https://docs.microsoft.com/en-us/azure/storage/common/storage-introduction)
- [ARM Template format for Microsoft.Storage/storageAccounts](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/2018-07-01/storageaccounts)
- [Storage Account Sku Type options](https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.management.storage.fluent.storageaccountskutype?view=azure-dotnet)

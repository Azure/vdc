# KeyVault

This module deploys Key Vault.

## Resources

- Microsoft.KeyVault/vaults
- Microsoft.KeyVault/vaults/providers/diagnosticsettings
- Microsoft.KeyVault/vaults/secrets

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `keyVaultName` | | Required. Name of the Azure Key Vault
| `accessPolicies` | `{}` | Optional. Access policies object
| `secretsObject` | `{}` | Optional. All secrets {\"secretName\":\"\",\"secretValue\":\"\"} wrapped in a secure object
| `enableVaultForDeployment` | `true` | Optional. Specifies if the vault is enabled for deployment by script or compute
| `enableVaultForTemplateDeployment` | `true` | Optional. Specifies if the vault is enabled for a template deployment
| `enableVaultForDiskEncryption` | `true` | Optional. Specifies if the azure platform has access to the vault for enabling disk encryption scenarios.
| `logsRetentionInDays` | `365` | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.
| `vaultSku` | `Premium` | Optional. Specifies the SKU for the vault
| `diagnosticStorageAccountId` | | Required. Resource identifier of the Diagnostic Storage Account.
| `workspaceId` | | Required. Resource identifier of Log Analytics.
| `networkAcls` | | Required. Service endpoint object information
| `vNetId` | | Required. Virtual Network resource identifier

## Outputs

| Output Name | Description |
| :-          | :-          |
| `keyVaultResourceId` | The Resource Id of the Key Vault.
| `keyVaultResourceGroup` | The name of the Resource Group the Key Vault was created in.
| `keyVaultName` | The Name of the Key Vault.
| `keyVaultUrl` | The Name of the Key Vault.

## Considerations

*N/A*

## Additional resources

- [What is Azure Key Vault?](https://docs.microsoft.com/en-us/azure/key-vault/key-vault-whatis)
- [Microsoft.KeyVault vaults template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.keyvault/2018-02-14/vaults)

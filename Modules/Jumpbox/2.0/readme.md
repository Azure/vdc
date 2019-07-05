# Jumpbox

This template deploys a Jumpbox.

## Resources

- Microsoft.Compute/virtualMachines
- Microsoft.Compute/availabilitySets
- Microsoft.Network/networkInterfaces
- Microsoft.Compute/virtualMachines/extensions
- Microsoft.Compute/virtualMachines/providers/guestConfigurationAssignments

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `windowsVirtualMachineName` | | Required. Name for the Jumpbox VM
| `linuxVirtualMachineName` | | Required. Name for the Jumpbox VM
| `workspaceId` | | Required. CustomerId value of Log Analytics. This value is referenced in MMA Extension
| `logAnalyticsWorkspacePrimarySharedKey` | | Required. WorkspaceKey value of OMS. This value is referenced in OMS VM Extension
| `artifactsStorageAccountKey` | | Required. Artifacts storage account Key. Storage account that contains output parameters and common scripts
| `artifactsStorageAccountName` | | Required. Artifacts storage account Name.
| `keyVaultURL` | `""` | Optional. AKV URI
| `keyVaultId` | `""` | Optional. AKV Resource Id
| `jumpboxKeyEncryptionURL` | `""` | Optional. Jumpbox AKV encryption key
| `vNetId` | | Required. Shared services Virtual Network resource Id
| `jumpboxAsgId` | | Required. Jumpbox ASG resource identifier
| `subnetName` | | Required. Name of Shared Services Subnet, this name is used to get the SubnetId
| `adminUserName` | | Required. The username used to establish jumpbox VMs.
| `adminPassword` | | Required. The password given to the admin user.
| `windowsVirtualMachineCount` | `1` | Optional. Number of jumpbox VMs to be created.
| `windowsVirtualMachineSize` | | Required. Size of the jumpbox VMs.
| `windowsOSImage` | | Required. OS image used for the jumpbox VMs.
| `linuxVirtualMachineCount` | `1` | Optional. Number of linux jumpbox VMs to be created.
| `linuxVirtualMachineSize` | | Required. Size of the jumpbox VMs.
| `linuxOSImage` | | Required. OS image used for the jumpbox VMs.
| `diagnosticsStorageAccountName` | | Required. Diagnostic Storage Account name
| `diagnosticsStorageAccountSasToken` | | Required. Diagnostic Storage Account SAS token

## Outputs

*N/A*

## Considerations

*N/A*

## Additional resources

- [Microsoft.Compute virtualMachines template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/2019-03-01/virtualmachines)
- [Microsoft.Compute availabilitySets template reference)[https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/2019-03-01/availabilitysets]
- [Microsoft.Network networkInterfaces template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-11-01/networkinterfaces)

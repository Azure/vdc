# Active Directory Domain Services

This template deploys Active Directory Domain Services.

## Resources

- Microsoft.Compute/availabilitySets
- Microsoft.Network/networkInterfaces
- Microsoft.Compute/virtualMachines
- Microsoft.Compute/virtualMachines/extensions
- Microsoft.Compute/virtualMachines/providers/guestConfigurationAssignments

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `virtualMachineName` | | Required. Name for the ADDS VMs
| `virtualMachineCount` | `2` | Optional. Number of VMs to create
| `virtualMachineSize` | `Standard_DS2_v2` | Optional. Size of the ADDS VMs
| `virtualMachineOSImage` | | Required. OS image used for the ADDS VMs
| `availabilitySetId` | `""` | Optional. Availability Set resource identifier, if a value is passed, these VMs will join the existing Availability Set.
| `artifactsStorageAccountSasKey` | | Required. Shared Access Signature Key used to download custom scripts
| `artifactsStorageAccountName` | | Required. Default storage account name. Storage account that contains output parameters and common scripts
| `artifactsStorageAccountKey` | | Required. Default storage account Key. Storage account that contains output parameters and common scripts
| `workspaceId` | | Required. WorkspaceId or CustomerId value of OMS. This value is referenced in OMS VM Extension
| `logAnalyticsWorkspacePrimarySharedKey` | | Required. WorkspaceKey value of OMS. This value is referenced in OMS VM Extension
| `diagnosticStorageAccountName` | | Required. Storage account used to store diagnostic information
| `diagnosticStorageAccountSasToken` | | Required. Diagnostic Storage Account SAS token
| `addsAddressStart` | | Required. IP address used as initial Active Directory Domain Services IP
| `keyVaultId` | `""` | Optional. AKV Resource Id
| `keyVaultURL` | `""` | Optional. AKV URL
| `addsKeyEncryptionURL` | `""` | Optional. Active Directory Domain Services AKV encryption key 
| `vNetId` | | Required. Shared services Virtual Network resource identifier
| `domainControllerAsgId` | | Required. ASG associated to Domain Controllers
| `subnetName` | | Required. Name of Shared Services Subnet, this name is used to get the SubnetId
| `adminUsername` | | Required. The username used to establish ADDS VMs
| `adminPassword` | | Required. The password given to the admin user
| `domainName` | | Required. AD domain name
| `primaryDCIP` | | Required. On-premises domain IP
| `ADSitename` | | Required. On-premises Active Directory site name
| `domaincontrollerDriveLetter` | | Required. Drive letter to install ADDS
| `domainAdminPassword` | | Required. Domain user that has privileges to join a VM into a Domain

## Outputs

| Output Name | Description |
| :-          | :-          |
| `aadsResourceGroup` | The Resource Group that was deployed to.

## Considerations

*N/A*

## Additional resources

- [Active Directory Domain Services](https://docs.microsoft.com/en-us/windows/desktop/ad/active-directory-domain-services)
- [Microsoft.Compute virtualMachines template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/2019-03-01/virtualmachines)

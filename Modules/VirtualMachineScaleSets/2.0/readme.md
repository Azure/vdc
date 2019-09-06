# Active Directory

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
| `virtualMachineName` | | Required. Name for the Active Directory VMs
| `virtualMachineSize` | `Standard_DS2_v2` | Optional. Size of the Active Directory VMs
| `virtualMachineOSImage` | | Required. OS image used for the Active Directory VMs| `artifactsStorageAccountSasKey` | | Required. Shared Access Signature Key used to download custom scripts
| `artifactsStorageAccountName` | | Required. Default storage account name. Storage account that contains output parameters and common scripts
| `artifactsStorageAccountKey` | | Required. Default storage account Key. Storage account that contains output parameters and common scripts
| `workspaceId` | | Required. WorkspaceId or CustomerId value of OMS. This value is referenced in OMS VM Extension
| `logAnalyticsWorkspacePrimarySharedKey` | | Required. WorkspaceKey value of OMS. This value is referenced in OMS VM Extension
| `diagnosticStorageAccountName` | | Required. Storage account used to store diagnostic information
| `diagnosticStorageAccountSasToken` | | Required. Diagnostic Storage Account SAS token
| `adIpAddress` | | Required. IP address used as primary Domain Controller IP
| `vNetId` | | Required. Shared services Virtual Network resource identifier
| `domainControllerAsgId` | | Required. ASG associated to Domain Controllers
| `subnetName` | | Required. Name of Shared Services Subnet, this name is used to get the SubnetId
| `cloudZone` | | Required. Cloud Zone to be created, this is useful when using one way  trust relationship
| `domainName` | | Required. AD domain name
| `adSitename` | | Required. On-premises Active Directory site name
| `keyVaultId` | `""` | Optional. AKV Resource Id
| `keyVaultURL` | `""` | Optional. AKV URL
| `adKeyEncryptionURL` | `""` | Optional. Active Directory AKV encryption key 
| `domainAdminUsername` | | Required. Domain user that has privileges to join a VM into a Domain
| `domainAdminPassword` | | Required. Domain user that has privileges to join a VM into a Domain

## Outputs

| Output Name | Description |
| :-          | :-          |
| `adResourceGroup` | The Resource Group that was deployed to.
| `dnsServers` | DNS Server IP
| `adAvailabilitySetResourceId` | Active Directory Availability Set Resource Identifier

## Considerations

*N/A*

## Additional resources

- [Active Directory Domain Services](https://docs.microsoft.com/en-us/windows/desktop/ad/active-directory-domain-services)
- [Microsoft.Compute virtualMachines template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/2019-03-01/virtualmachines)

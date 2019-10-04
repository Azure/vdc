# Virtual Machines

This template deploys one or multiple Virtual Machines.

## Resources

- Microsoft.Compute/availabilitySets
- Microsoft.Network/networkInterfaces
- Microsoft.Compute/virtualMachines
- Microsoft.Compute/virtualMachines/extensions
- Microsoft.Compute/virtualMachines/providers/guestConfigurationAssignments

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `virtualMachineName` | | Required. Name for the Active Directory VMs.
| `virtualMachineSize` | `Standard_DS2_v2` | Optional. Size of the Active Directory VMs.
| `virtualMachineOSImage` | | Required. OS image used for the Active Directory VMs| `artifactsStorageAccountSasKey` | | Required. Shared Access Signature Key used to download custom scripts.
| `virtualMachineOSType` | | Required. Select Windws or Linux.
| `virtualMachineCount` | `1` | Optional. Number of VMs to create.
| `virtualMachineOffset` | `1` | Optional. This value will be used as start VM count. Specify a value if you want to create VMs starting at a specific number, this is useful when you want to append more VMs.
| `virtualMachineDataDisks` | | Optional. Array of objects with the following expected format: [{ 'size': 120 }, { 'size': 130 }], this array indicates that two data disks will be created.
| `availabilitySetId` | | Optional. Availability Set resource identifier, if a value is passed, the VMs will be associated to this Availability Set.
| `customData` | | Optional. Custom data associated to the VM, this value will be automatically converted into base64 to account for the expected VM format.
| `workspaceId` | | Required. WorkspaceId or CustomerId value of OMS. This value is referenced in OMS VM Extension.
| `logAnalyticsWorkspaceId` | | Required. The Resource Id of the Log Analytics workspace deployed.
| `logAnalyticsWorkspacePrimarySharedKey` | | Required. WorkspaceKey value of OMS. This value is referenced in OMS VM Extension.
| `diagnosticStorageAccountId` | | Required. The Resource Id of the Storage Account.
| `diagnosticStorageAccountName` | | Required. Storage account used to store diagnostic information.
| `diagnosticStorageAccountSasToken` | | Required. Diagnostic Storage Account SAS token.
| `diagnosticLogsRetentionInDays` | `365` | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely. 
| `artifactsStorageAccountName` | | Required. Default storage account name. Storage account that contains output parameters and common scripts.
| `artifactsStorageAccountKey` | | Required. Default storage account Key. Storage account that contains output parameters and common scripts.
| `artifactsStorageAccountSasKey` | | Required. Shared Access Signature Key used to download custom scripts.
| `vmIPAddress` | | Optional. IP address used as initial IP address. If left empty, the VM will use the next available IP
| `vNetId` | | Required. Shared services Virtual Network resource identifier.
| `subnetName` | | Required. Name of Shared Services Subnet, this name is used to get the SubnetId.
| `loadBalancerBackendPoolId` | | Optional. Represents a Load Balancer backend pool resource identifier, if left blank, no Load Balancer will be associated to the VMSS.
| `applicationSecurityGroupId` | | Optional. Application Security Group to associate to the Network Interface. If left empty, the Network Interface would not be associated to any Application Security Group.
| `adminUsername` | | Required. Administrator username.
| `adminPassword` | | Optional. When specifying a Windows Virtual Machine, this value should be passed.
| `sshPublicKey` | | Optional. SSH public key. When specifying a Linux Virtual Machine, this value should be passed. Linux VMs can be accessed via SSH public key only..
| `proximityPlacementGroupsId` | | Optional. If passed, the VM will be assigned to a Proximity Placement Groups.
| `location` | | Optional. Location for all resources.
| `enablePublicIp` | `false` | Optional. Optional. Enables the creation of a Public IP and assigns it to the Network Interface. 
| `domainAdminUsername` | | Optional. Domain user that has privileges to join a VM into a Domain. If joinToDomain is set to true, this value becomes required.
| `domainAdminPassword` | | Optional. Domain user that has privileges to join a VM into a Domain. If joinToDomain is set to true, this value becomes required.
| `domainName` | | Optional. AD domain name. If joinToDomain is set to true, this value becomes required.

## Outputs

| Output Name | Description |
| :-          | :-          |
| `vmResourceGroup` | The Resource Group that was deployed to.
| `vmNames` | The name of the VMs provisioned. Array. 
| `vmResourceIds` | They resource identifier of the VMs provisioned. 

## Considerations

*N/A*

## Additional resources

- [Microsoft.Compute virtualMachines template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.compute/2019-03-01/virtualmachines)

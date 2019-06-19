# ApplicationSecurityGroups

This module deploys Application Security Groups.

## Resources

- Microsoft.Network/applicationSecurityGroups

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `applicationSecurityGroupName` | | Required. Name of the Application Security Group.

## Outputs

| Output Name | Description |
| :-          | :-          |
| `applicationSecurityGroupResourceGroup` | The name of the Resource Group the Application Security Groups were created in.
| `applicationSecurityGroupResourceId` | The Resource Ids of the Network Security Group deployed.
| `applicationSecurityGroupName` | The Name of the Application Security Group deployed.

## Considerations

*N/A*

## Additional resources

- [Application Security Groups](https://docs.microsoft.com/en-us/azure/virtual-network/security-overview#application-security-groups)
- [Microsoft.Network applicationSecurityGroups template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-08-01/applicationsecuritygroups)
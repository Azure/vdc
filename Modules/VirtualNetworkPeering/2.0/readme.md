# vNetPeering

This template deploys Virtual Network Peering.

## Resources

- Microsoft.Network/virtualNetworks/virtualNetworkPeerings

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `localVnetName` | | Required. The Name of the Virtual Network to add the peering to.
| `peeringName` | | Require. The Name of the virtual network peering resource.
| `remoteVirtualNetworkId` | | Required. The Resource Id of the remote virtual network. The remove virtual network can be in the same or different region.
| `allowVirtualNetworkAccess` | `true` | Optional. Whether the VMs in the local virtual network space would be able to access the VMs in remote virtual network space.
| `allowForwardedTraffic` | | Optional. Whether the forwarded traffic from the VMs in the local virtual network will be allowed/disallowed in remote virtual network.
| `allowGatewayTransit` | | Optional. If gateway links can be used in remote virtual networking to link to this virtual network.
| `useRemoteGateways` | | Optional. If remote gateways can be used on this virtual network. If the flag is set to true, and allowGatewayTransit on remote peering is also true, virtual network will use gateways of remote virtual network for transit. Only one peering can have this flag set to true. This flag cannot be set if virtual network already has a gateway.

## Outputs

| Output Name | Description |
| :-          | :-          |
| `vNetPeeringResourceResourceGroup` | The Resource Group the vNet Peering was deployed to.
| `vNetPeeringName` | The Name of the vNet Peering.
| `vNetPeeringResourceId` | The Resource Id of the vNet Peering.

## Considerations

N/A

## Additional resources

- [Microsoft.Network virtualNetworks/virtualNetworkPeerings template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2019-04-01/virtualnetworks/virtualnetworkpeerings)

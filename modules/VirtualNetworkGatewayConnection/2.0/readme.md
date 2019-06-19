# VirtualNetworkGatewayConnection

This template deploys Virtual Network Gateway Connection.

## Resources

- Microsoft.Network/connections

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `localVirtualNetworkGatewayName` | | Required. Specifies the local Virtual Network Gateway name
| `vpnSharedKey` | | Required. Specifies a VPN shared key. The same value has to be specified on both Virtual Network Gateways
| `remoteVirtualNetworkGatewayName` | | Required. Specifies the remote Virtual Network Gateway
| `remoteVirtualNetworkResourceGroup` | | Required. Remote Virtual Network resource group name
| `remoteVirtualNetworkGatewaySubscriptionId` | | Required. Remote Subscription Id
| `enableBgp` | `false` | Optional. Value to specify if BGP is enabled or not
| `remoteConnectionName` | | Required. Remote connection name
| `virtualNetworkGatewayConnectionType` | `VNet2VNet` | Optional. Gateway connection type.

## Outputs

| Output Name | Description |
| :-          | :-          |
| `remoteConnectionResourceGroup` | The Resource Group deployed it.
| `remoteConnectionName` | The Name of the Virtual Network Gateway Connection.
| `remoteConnectionResourceId` | The Resource Id of the Virtual Network Gateway Connection.

## Considerations

*N/A*

## Additional resources

- [Microsoft.Network connections template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-11-01/connections)

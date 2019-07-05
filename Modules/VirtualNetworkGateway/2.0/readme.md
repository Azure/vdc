# VirtualNetworkGateway

This module deploys a Virtual Network Gateway.

## Resources

- Microsoft.Network/virtualNetworkGateways
- Microsoft.Network/publicIPAddresses

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `virtualNetworkGatewayName` | | Required. Specifies the Virtual Network Gateway name.
| `virtualNetworkGatewayType` | | Required. Specifies the gateway type. E.g. VPN, ExpressRoute
| `virtualNetworkGatewaySku` | | Required. The Sku of the Gateway. This must be one of Basic, Standard or HighPerformance.
| `vpnType` | | Required. Specifies the VPN type
| `vNetId` | | Required. Virtual Network resource Id
| `enableBgp` | `true` | Optional. Value to specify if BGP is enabled or not
| `asn` | `65815` | Optional. ASN value

## Outputs

| Output Name | Description |
| :-          | :-          |
| `virtualNetworkGatewayResourceGroup` | The Resource Group the Virtual Network Gateway was deployed.
| `virtualNetworkGatewayName` | The Name of the Virtual Network Gateway.
| `virtualNetworkGatewayId` | The Resource Id of the Virtual Network Gateway.

## Considerations

*N/A*

## Additional resources

- [Microsoft.Network virtualNetworkGateways template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-11-01/virtualnetworkgateways)

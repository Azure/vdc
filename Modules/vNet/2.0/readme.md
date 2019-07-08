# vNet

This template deploys a Virtual Network (vNet) with 2 optional Subnets.

## Resources

- Microsoft.Network/virtualNetworks
- Microsoft.Network/virtualNetworks/subnet

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `vnetName` | | Required. The Virtual Network (vNet) Name.
| `vnetAddressPrefix` | | Required. An Array of 1 or more IP Address Prefixes for the Virtual Network.
| `subnets` | | Required. An Array of subnets to deploy to the Virtual Network.
| `ddosProtectionPlanResourceId` | *empty* | Optional. The Resource Id of the DDoS Protection Plan.
| `enableDdosProtection` | `true` | Optional. Indicates if DDoS protection is enabled for all the protected resources in the Virtual Network. A 'true' value requires a DDoS Protection Plan to be specified.
| `enableVmProtection` | `true` | Optional. Indicates if VM protection is enabled for all the subnets in the Virtual Network.

### Parameter Usage: `vnetAddressPrefix`

The `vnetAddressPrefix` parameter accepts a JSON Array of string values containing the IP Address Prefixes for the Virtual Network (vNet).

Here's an example of specifying a single Address Prefix:

```
"vnetAddressPrefix": {
    "value": [
        "10.1.0.0/16"
    ]
}
```

### Parameter Usage: `subnets`

The `subnets` parameter accepts a JSON Array of `subnet` objects to deploy to the Virtual Network.

Here's an example of specifying a couple Subnets to deploy:

```
"subnets": {
    "value": [
    {
        "name": "app",
        "properties": {
        "addressPrefix": "10.1.0.0/24",
        "networkSecurityGroup": {
            "id": "[resourceId('Microsoft.Network/networkSecurityGroups', 'app-nsg')]"
        },
        "routeTable": {
            "id": "[resourceId('Microsoft.Network/routeTables', 'app-udr')]"
        }
        }
    },
    {
        "name": "data",
        "properties": {
        "addressPrefix": "10.1.1.0/24"
        }
    }
    ]
}
```

## Outputs

| Output Name | Description |
| :-          | :-          |
| `vNetResourceGroup` |The name of the Resource Group the Virtual Network was created in.
| `vNetResourceId` | The Resource id of the Virtual Network deployed.
| `vNetName` | The name of the Virtual Network deployed.
| `subnetNames` | The Names of the Subnets deployed to the Virtual Network.
| `subnetIds` | The Resource Ids of the Subnets deployed to the Virtual Network.

## Considerations

When defining the Subnets to deploy using the `subnets` parameter, the JSON format to pass it must match the Subnet object that is normally passed in to the `subnets` property of a `virtualNetwork` within an ARM Template.

## Additional resources

- [Microsoft.Network virtualNetworks template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-08-01/virtualnetworks)
- [Subnet object template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-08-01/virtualnetworks#Subnet)
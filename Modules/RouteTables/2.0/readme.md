# RouteTables

This template deploys User Defined Route Tables.

## Resources

- Microsoft.Network/routeTables

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `routeTableName` | | Required. Name given for the hub route table.
| `routes` | [] | Optional. An Array of Routes to be established within the hub route table.

### Parameter Usage: ``

The `routes` parameter accepts a JSON Array of Route objects to deploy to the Route Table.

Here's an example of specifying a few routes:

```
"routes": {
  "value": [
    {
      "name": "tojumpboxes",
      "properties": {
        "addressPrefix": "172.16.0.48/28",
        "nextHopType": "VnetLocal"
      }
    },
    {
      "name": "tosharedservices",
      "properties": {
        "addressPrefix": "172.16.0.64/27",
        "nextHopType": "VnetLocal"
      }
    },
    {
      "name": "toonprem",
      "properties": {
        "addressPrefix": "10.0.0.0/8",
        "nextHopType": "VirtualNetworkGateway"
      }
    },
    {
      "name": "tonva",
      "properties": {
        "addressPrefix": "172.16.0.0/18",
        "nextHopType": "VirtualAppliance",
        "nextHopIpAddress": "172.16.0.20"
      }
    }
  ]
}
```

## Outputs

| Output Name | Description |
| :-          | :-          |
| `routeTableResourceGroup` | The name of the Resource Group the Route Table was deployed to.
| `routeTableName` | The name of the Route Table deployed.
| `routeTableResourceId` | The Resource id of the Virtual Network deployed.

## Considerations

*N/A*

## Additional resources

- [Microsoft.Network routeTables template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-11-01/routetables)

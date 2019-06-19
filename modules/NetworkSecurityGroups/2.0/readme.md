# NetworkSecurityGroups

This template deploys a Network Security Groups (NSG) with optional security rules.

## Resources

- Microsoft.Network/networkSecurityGroups

## Parameters

| Parameter Name | Default Value | Description
| :-             | :-            | :-
| `workspaceId` | | Resource Id of the Log Analytics workspace.
| `diagnosticStorageAccountId` | | Required. Resource Id of the diagnostics Storage Account.
| `logRetentionInDays` | 365 | Optional. Information about how many days log information will be retained in a diagnostic Storage Account.
| `networkSecurityGroupName` | | Required. Name of the Network Security Group.
| `networkSecurityGroupSecurityRules` | | Required. Array of Security Rules to deploy to the Network Security Group.

### Parameter Usage: `networkSecurityGroupSecurityRules`

The `networkSecurityGroupSecurityRules` parameter accepts a JSON Array of `securityRule` to deploy to the Network Security Group (NSG).

Here's an example of specifying a couple security rules:

```json
    "networkSecurityGroupSecurityRules": {
      "value": [
        {
          "name": "Port_8080",
          "properties": {
              "protocol": "*",
              "sourcePortRange": "*",
              "destinationPortRange": "8080",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": null,
              "access": "Allow",
              "priority": 100,
              "direction": "Inbound",
              "sourcePortRanges": [],
              "destinationPortRanges": [],
              "sourceAddressPrefixes": [],
              "destinationAddressPrefixes": [],
              "destinationApplicationSecurityGroups": [
                  {
                    "name": "test-asg"
                  }
              ],
              "sourceApplicationSecurityGroups": []
          }
        },
        {
            "name": "Port_RDP",
            "properties": {
                "protocol": "TCP",
                "sourcePortRange": "*",
                "destinationPortRange": "3389",
                "sourceAddressPrefix": "*",
                "destinationAddressPrefix": "*",
                "access": "Allow",
                "priority": 110,
                "direction": "Inbound",
                "sourcePortRanges": [],
                "destinationPortRanges": [],
                "sourceAddressPrefixes": [],
                "destinationAddressPrefixes": [],
                "destinationApplicationSecurityGroups": [],
                "sourceApplicationSecurityGroups": []
            }
        }

      ]

    }
```

## Outputs

| Output Name | Description |
| :- | :- |
| `networkSecurityGroupResourceGroup` | The name of the Resource Group the Network Security Groups were created in.
| `networkSecurityGroupResourceId` | The Resource Ids of the Network Security Group deployed.
| `networkSecurityGroupName` | The Name of the Network Security Group deployed.

## Considerations

When specifying the Security Rules for the Network Security Group (NSG) with the `networkSecurityGroupSecurityRules` parameter, pass in the Security Rules as a JSON Array in the same format as would be used for the `securityRules` property of the `Microsoft.Network/networkSecurityGroups` resource provider in an ARM Template.

## Additional resources

- [Azure Network Security Groups](https://docs.microsoft.com/en-us/azure/virtual-network/security-overview)
- [Microsoft.Network networkSecurityGroups template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-11-01/networksecuritygroups)
- [Microsoft.Network networkSecurityGroups/securityRules template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-11-01/networksecuritygroups/securityrules)
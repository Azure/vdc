# AzureFirewall

This module deploys Azure Firewall.

## Resources

- Microsoft.Network/azureFirewalls
- Microsoft.Network/azureFirewalls/providers/diagnosticsettings
- Microsoft.Network/publicIPAddresses

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `azureFirewallName` | | Required. Name of the Azure Firewall.
| `applicationRuleCollections` | | Required. Collection of application rule collections used by Azure Firewall.
| `networkRuleCollections` | | Required. Collection of network rule collections used by Azure Firewall.
| `vNetId` | | Required. Shared services Virtual Network resource Id
| `diagnosticStorageAccountId` | | Required. Diagnostic Storage Account resource identifier
| `workspaceId` | | Required. Log Analytics workspace resource identifier
| `logsRetentionInDays` | `365` | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.

## Outputs

| Output Name | Description |
| :-          | :-          |
| `azureFirewallResourceId` | The Resource Id of the Azure Firewall.
| `azureFirewallName` | The Name of the Azure Firewall.
| `azureFirewallResourceGroup` | The name of the Resource Group the Azure Firewall was created in.
| `azureFirewallPrivateIp` | The private IP of the Azure Firewall.
| `azureFirewallPublicIp` | The public IP of the Azure Firewall.
| `applicationRuleCollections` | List of Application Rule Collections.
| `networkRuleCollections` | List of Network Rule Collections.

## Considerations

The `applicationRuleCollections` parameter accepts a JSON Array of AzureFirewallApplicationRule objects.

The `networkRuleCollections` parameter accepts a JSON Array of AzureFirewallNetworkRuleCollection objects.

## Additional resources

- [Microsoft.Network azureFirewalls template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-08-01/azurefirewalls)
- [AzureFirewallApplicationRuleCollection object reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-08-01/azurefirewalls#AzureFirewallApplicationRuleCollection)
- [AzureFirewallNetworkRuleCollection object reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.network/2018-08-01/azurefirewalls#AzureFirewallNetworkRuleCollection)
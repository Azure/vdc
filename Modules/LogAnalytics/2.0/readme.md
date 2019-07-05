# LogAnalytics

This template deploys Log Analytics.

## Resources

- Microsoft.OperationalInsights/workspaces
- Microsoft.OperationalInsights/workspaces/savedSearches
- Microsoft.OperationalInsights/workspaces/datasources
- Microsoft.OperationalInsights/workspaces/storageinsightconfigs
- Microsoft.OperationalInsights/workspaces/providers/locks
- Microsoft.OperationsManagement/solutions

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `logAnalyticsWorkspaceName` | | Required. Name of the Log Analytics workspace
| `serviceTier` | | Required. Service Tier: Free, Standalone, PerGB or PerNode
| `dataRetention` | | Required. Number of days data will be retained for
| `location` | | Required. Region used when establishing the workspace
| `diagnosticStorageAccountName` | | Required. Diagnostic Storage Account name
| `diagnosticStorageAccountResourceId` | | Required. Log Analytics workspace resource identifier
| `diagnosticStorageAccountAccessKey` | | Required. Diagnostic Storage Account key
| `automationAccountId` | `""` | Optional. Automation Account resource identifier, value used to create a LinkedService between Log Analytics and an Automation Account

## Outputs

| Output Name | Description |
| :-          | :-          |
| `logAnalyticsWorkspaceResourceId` | The Resource Id of the Log Analytics workspace deployed.
| `logAnalyticsWorkspaceResourceGroup` | The Resource Group log analytics was deployed to.
| `logAnalyticsWorkspaceName` | The Name of the Log Analytics workspace deployed.
| `logAnalyticsWorkspaceId` | The Workspace Id for Log Analytics.
| `logAnalyticsPrimarySharedKey` | The Primary Shared Key for Log Analytics.

## Considerations

*N/A*

## Additional resources

- [Microsoft.OperationalInsights workspaces template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/2015-11-01-preview/workspaces)
- [Microsoft.OperationalManagement solutions template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.operationsmanagement/2015-11-01-preview/solutions)

# AutomationAccounts

This module deploys an Azure Automation Account.

## Resources

- Microsoft.Automation/automationAccounts
- Microsoft.Automation/automationAccounts/providers/diagnosticsettings
- Microsoft.Automation/automationAccounts/softwareUpdateConfigurations

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `automationAccountName` | | Required. Specifies the Automation Account name.
| `location` | | Required. Specifies the region for your Automation Account
| `month` | `[utcNow('MM')]` | Optional. Format: yyyy/mm/dd hh:mm:ss AM/PM, start time must be at least 5 minutes after the time you create the schedule
| `year` | `[utcNow('yyyy')]` | Optional. Format: yyyy/mm/dd hh:mm:ss AM/PM, start time must be at least 5 minutes after the time you create the schedule
| `umTimeZone` | | Required. Time zone format is based on IANA ID and restricted to below values only for now, full list at: <https://docs.microsoft.com/en-us/rest/api/maps/timezone/gettimezoneenumwindows>
| `workspaceId` | | Required. Resource Id of the Log Analytics workspace.
| `diagnosticStorageAccountId` | | Required. Resource Id of the diagnostics Storage Account.
| `logRetentionInDays` | `365` | Optional. Information about how many days log information will be retained in a diagnostic Storage Account.

## Outputs

| Output Name | Description |
| :-          | :-          |
| `automationAccountResourceId` | The Resource Id of the Automation Account.
| `automationAccountResourceGroup` | The Resource Group the Automation Account was deployed to.
| `automationAccountName` | The Name of the Automation Account.

## Considerations

*N/A*

## Additional resources

- [An introduction to Azure Automation](https://docs.microsoft.com/en-us/azure/automation/automation-intro)
- [Microsoft.Automation automationAccounts template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.automation/2015-10-31/automationaccounts)

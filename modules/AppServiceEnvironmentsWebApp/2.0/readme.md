# AppServiceEnvironmentsWebApp

This module deploys an Azure Web App to an App Service Environment and App Service Plan.

## Resources

- Microsoft.Web/sites

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `appServiceEnvironmentWebAppName` | | Required. The Name of the Web App to deploy.
| `appServiceEnvironmentId` | | Required. The Resource Id of the App Service Environment to use for the App Service Plan.
| `appServiceEnvironmentPlanId` | | Required. The Resource Id of the App Service Plan within the App Service Environment to host the Web App.

## Outputs

| Output Name | Description |
| :-          | :-          |
| `appServiceEnvironmentWebAppResourceGroup` | The Resource Group the Web App was deployed to.
| `appServiceEnvironmentWebAppName` | The Name of the Web App that was deployed.
| `appServiceEnvironmentWebAppResourceId` | The Resource Id of the Web App that was deployed.

## Considerations

*N/A*

## Additional resources

- [Microsoft.Web sites template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.web/2018-02-01/sites)

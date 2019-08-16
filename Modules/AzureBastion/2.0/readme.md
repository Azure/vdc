# AppServiceEnvironmentsWebApp

This module deploys an Azure Web App to an App Service or App Service Environment and to its corresponding App Service Plan.

## Resources

- Microsoft.Web/sites

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `appServiceWebAppName` | | Required. The Name of the Web App to deploy.
| `appServiceEnvironmentId` | | Optional. The Resource Id of the App Service Environment to use for the App Service Plan.
| `appServicePlanId` | | Required. The Resource Id of the App Service Plan within the App Service Environment to host the Web App.

## Outputs

| Output Name | Description |
| :-          | :-          |
| `appServiceWebAppResourceGroup` | The Resource Group the Web App was deployed to.
| `appServiceWebAppName` | The Name of the Web App that was deployed.
| `appServiceWebAppResourceId` | The Resource Id of the Web App that was deployed.

## Considerations

*N/A*

## Additional resources

- [Microsoft.Web sites template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.web/2018-02-01/sites)

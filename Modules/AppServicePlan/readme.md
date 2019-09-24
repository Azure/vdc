# AppServiceEnvironmentsWebApp

This module deploys an App Service Plan to an App Service or App Service Environment.

## Resources

- Microsoft.Web/serverfarms

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `appServicePlanName` | | Required. The Name of the App Service Plan to deploy.
| `appServiceEnvironmentId` | | Optional. The Resource Id of the App Service Environment to use for the App Service Plan.
| `sku` | | Required. Defines the name, tier, size, family and capacity of the App Service Plan.

## Outputs

| Output Name | Description |
| :-          | :-          |
| `appServicePlanResourceGroup` | The Resource Group the App Service Plan was deployed to.
| `appServicePlanName` | The Name of the App Service Plan that was deployed.
| `appServicePlanResourceId` | The Resource Id of the App Service Plan that was deployed.

## Considerations

*N/A*

## Additional resources

- [Microsoft.Web serverfarms template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.web/2018-02-01/serverfarms)

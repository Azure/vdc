# AppServiceEnvironmentsWebApp

This module deploys an App Service Plan to an App Service Environment.

## Resources

- Microsoft.Web/serverfarms

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `appServiceEnvironmentPlanName` | | Required. The Name of the App Service Plan to deploy.
| `appServiceEnvironmentId` | | Required. The Resource Id of the App Service Environment to use for the App Service Plan.
| `appServicePlanWorkerPool` | `1` | Optional. Defines which worker pool's (WP1, WP2 or WP3) resources will be used for the app service plan.
| `appServicePlanNumberOfWorkersFromWorkerPool` | `1` | Optional. Defines the number of workers from the worker pool that will be used by the app service plan.

## Outputs

| Output Name | Description |
| :-          | :-          |
| `appServiceEnvironmentPlanResourceGroup` | The Resource Group the App Service Plan was deployed to.
| `appServiceEnvironmentPlanName` | The Name of the App Service Plan that was deployed.
| `appServiceEnvironmentPlanResourceId` | The Resource Id of the App Service Plan that was deployed.

## Considerations

*N/A*

## Additional resources

- [Microsoft.Web serverfarms template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.web/2018-02-01/serverfarms)

# AppServiceEnvironments

This template deploys an Application Service Environment.

## Resources

- Microsoft.Web/hostingEnvironments

## Parameters

| Parameter Name | Default Value | Description |
| :-             | :-            | :-          |
| `appServiceEnvironmentName` | | Required. The name of the App Service Environment.
| `dnsSuffix` | `""` | Optional. The DNS Suffix to use for the default App Service Environment domain name.
| `vnetResourceGroup` | | Required. The Resource Group of the Virtual Network.
| `vnetName` | | Required. The Name of the Virtual Network to connect the App Service Environment.
| `subnetName` | `default` | Optional. The name of the Virtual Network Subnet to connect the App Service Environment.
| `internalLoadBalancingMode` | `None` | Optional. Specifies which endpoints to serve internally in the Virtual Network for the App Service Environment.
| `ipSSLAddressCount` | `1` | Optional. Number of IP addresses reserved for the App Service Environment.  This value *must* be zero when internalLoadBalancing mode is set to either None or Publishing.
| `multiSize` | `Standard_D1_V2` | Optional. Front-end VM size.
| `multiRoleCount` | `2` | Optional. Number of front-end instances.
| `workerPools` | `[{ "workerSizeId": 0, "workerSize": "Small", "workerCount": "2" }]` | Optional. Description of worker pools with worker size IDs, VM sizes, and number of workers in each pool.

### Parameter Usage: `workerPools`

The `workerPools` parameter accepts a JSON Array of [WorkerPool](https://docs.microsoft.com/en-us/azure/templates/microsoft.web/2018-02-01/hostingenvironments#WorkerPool) objects that define the Worker Pools to configure in the App Service Environment. There must be at least 1 Worker Pool defined.

Here's an example of specifying a single Worker Pool:

```json
[
    {
        "workerSizeId": 0,
        "workerSize": "Small",
        "workerCount": "2"
    }
]
```

## Outputs

| Output Name | Description |
| :-          | :-          |
| `appServiceEnvironmentResourceGroup` | The Resource Group the App Service Environment was deployed to.
| `appServiceEnvironmentName` | The Name of the App Service Environment.
| `appServiceEnvironmentResourceId` | The Resource Id of the App Service Environment.

## Considerations

*N/A*

## Additional resources

- [Microsoft.Web hostingEnvironments template reference](https://docs.microsoft.com/en-us/azure/templates/microsoft.web/2018-02-01/hostingenvironments)


Class IDeploymentService {

    [hashtable] ExecuteDeployment([string] $tenantId, `
                                  [string] $subscriptionId, `
                                  [string] $resourceGroupName, `
                                  [string] $deploymentTemplate, `
                                  [string] $deploymentParameters,
                                  [string] $location) {
        Throw "Method Not Implemented";
    }

    CreateResourceGroup([string] $resourceGroupName,
                        [string] $location) {
        Throw "Method Not Implemented";
    } 
}
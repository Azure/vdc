
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

    [void] SetSubscriptionContext([guid] $subscriptionId,
                                  [guid] $tenantId) {
        Throw "Method Not Implemented";
    }
}
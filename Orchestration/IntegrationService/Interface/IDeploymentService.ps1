
Class IDeploymentService {

    [hashtable] ExecuteDeployment([string] $tenantId, `
                                  [string] $subscriptionId, `
                                  [string] $resourceGroupName, `
                                  [string] $deploymentTemplate, `
                                  [string] $deploymentParameters,
                                  [string] $location) {
        Throw "Method Not Implemented";
    }

    [void] CreateResourceGroup([string] $resourceGroupName,
                               [string] $location) {
        Throw "Method Not Implemented";
    }

    [void] SetSubscriptionContext([guid] $subscriptionId,
                                  [guid] $tenantId) {
        Throw "Method Not Implemented";
    }

    [void] RemoveResourceGroupLock([guid] $subscriptionId,
                                   [string] $resourceGroupName) {
        Throw "Method Not Implemented";
    }

    [void] RemoveResourceGroup([guid] $subscriptionId,
                               [string] $resourceGroupName) {
        Throw "Method Not Implemented";
    }

    [object] GetResourceGroup([guid] $subscriptionId,
                              [string] $resourceGroupName) {
        Throw "Method Not Implemented";
    }
}
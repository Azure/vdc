Class IModuleStateDataService {

    [Guid] SaveResourceState([Guid] $auditId, `
                        [string] $deploymentId, `
                        [string] $archetypeInstanceName, `
                        [string] $moduleInstanceName, `
                        [string] $resourceState, `
                        [string] $deploymentOutpus, `
                        [string] $tenantId, `
                        [string] $subscriptionId, `
                        [string] $policies, `
                        [string] $rbac) {
        Throw "Method Not Implemented";
    }

    [object] GetResourceStateById([object] $stateId) {
        Throw "Method Not Implemented";
    }

    [object] GetResourceStateByFilters([object[]] $filters) {
        Throw "Method Not Implemented";
    }

    [object] GetResourceStateOutputs([string] $archetypeInstanceName, `
                                     [string] $moduleInstanceName) {
        Throw "Method Not Implemented";
    }
}
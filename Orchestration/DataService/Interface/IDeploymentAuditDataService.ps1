Class IDeploymentAuditDataService {

    [Guid] SaveAuditTrail( [string] $buildId, `
                    [string] $buildName, `
                    [string] $commitId, `
                    [string] $userId, `
                    [string] $tenantId, `
                    [string] $subscriptionId, `
                    [string] $archetypeInstance, `
                    [string] $archetypeInstanceName) {
        Throw "Method Not Implemented";
    }

    [object] GetAuditTrailById([string] $auditId) {
        Throw "Method Not Implemented";
    }

    [object] GetAuditTrailByFilters([object[]] $filters) {
        Throw "Method Not Implemented";
    }

    [object] GetAuditTrailByBuildId([string] $buildId) {
        Throw "Method Not Implemented";
    }

    [object] GetAuditTrailByCommitId([string] $commitId) {
        Throw "Method Not Implemented";
    }

    [object] GetAuditTrailByUserId([string] $userId) {
        Throw "Method Not Implememted";
    }
}
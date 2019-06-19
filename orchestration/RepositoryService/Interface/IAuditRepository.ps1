Class IAuditRepository {

    [void] SaveAuditTrail([object] $entity) {
                            Throw "Method Not Implemented";
    }

    [void] GetAuditTrailByCommitId ([object] $commitId) {
        Throw "Method Not Implemented";
    }

    [object] GetAuditTrailById([object] $auditId) {
        Throw "Method Not Implemented";
    }

    [object] GetAuditTrailByUserId([object] $userId) {
        Throw "Method Not Implemented";
    }

    [object] GetAuditTrailByBuildId([object] $buildId) {
        Throw "Method Not Implemented";
    }
}
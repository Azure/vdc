Class DeploymentAuditDataService: IDeploymentAuditDataService {

    $auditRepository = $null;

    DeploymentAuditDataService([IAuditRepository] $auditRepository) {
        $this.auditRepository = $auditRepository;
    }

    [Guid] SaveAuditTrail([string] $buildId, `
                    [string] $buildName, `
                    [string] $commitId, `
                    [string] $commitMessage, `
                    [string] $commitUsername, `
                    [string] $buildQueuedBy, `
                    [string] $releaseId, `
                    [string] $releaseName, `
                    [string] $releaseRequestedFor,`
                    [string] $tenantId, `
                    [string] $subscriptionId, `
                    [object] $archetypeInstance, `
                    [string] $archetypeInstanceName) {
        
        try {
            $auditId = [Guid]::NewGuid();
            $entity = @{
                AuditId = $auditId.ToString()
                BuildId = $buildId
                BuildName = $buildName
                CommitId = $commitId
                CommitMessage = $commitMessage
                CommitUsername = $commitUsername
                BuildQueuedBy = $buildQueuedBy
                ReleaseId = $releaseId
                ReleaseName = $releaseName
                ReleaseRequestedFor = $releaseRequestedFor
                TenantId = $tenantId
                SubscriptionId = $subscriptionId
                ArchetypeInstance = $archetypeInstance
                ArchetypeInstanceName = $archetypeInstanceName
            }

            $this.auditRepository.SaveAuditTrail(
                $entity
            );

            $this.auditRepository.SaveAuditTrailAndDeploymentIdMapping(
                $entity
            );

            return $auditId;
        }
        catch {
            Write-Host "An error occurred while running DeploymentAuditDataService.SaveAuditTrail";
            Write-Host $_;
            throw $_;
        }
    }

    [object] GetAuditTrailById([string] $auditId) {
        return $this.auditRepository.GetAuditTrailById($auditId);
    }

    [object] GetAuditTrailByFilters([object[]] $filters) {
        return $this.auditRepository.GetAuditTrailByFilters($filters);
    }

    [object] GetAuditTrailByBuildId([string] $buildId) {
        return $this.auditRepository.GetAuditTrailByBuildId($buildId);
    }

    [object] GetAuditTrailByCommitId([string] $commitId) {
        return $this.auditRepository.GetAuditTrailByCommitId($commitId);
    }

    [object] GetAuditTrailByUserId([string] $userId) {
        return $this.auditRepository.GetAuditTrailByUserId($userId);
    }
}
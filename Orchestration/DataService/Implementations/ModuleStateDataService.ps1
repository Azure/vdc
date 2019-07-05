Class ModuleStateDataService: IModuleStateDataService {
    
    $stateRepository = $null;

    ModuleStateDataService([IStateRepository] $stateRepository) {
        $this.stateRepository = $stateRepository;
    }
    
    [Guid] SaveResourceState([guid] $auditId, `
                        [string] $deploymentId, `
                        [string] $deploymentName, `
                        [string] $archetypeInstanceName, `
                        [string] $moduleInstanceName, `
                        [object] $resourceStates, `
                        [object] $resourceIds, `
                        [string] $resourceGroupName, `
                        [object] $deploymentTemplate, `
                        [object] $deploymentParameters, `
                        [object] $deploymentOutputs, `
                        [string] $tenantId, `
                        [string] $subscriptionId, `
                        [object] $policies, `
                        [object] $rbac) {
        
        try {
            $stateId = [Guid]::NewGuid();
            $entity = @{
                StateId = $stateId.ToString()
                DeploymentId = $deploymentId
                DeploymentName = $deploymentName
                ArchetypeInstanceName = $archetypeInstanceName
                ModuleInstanceName = $moduleInstanceName
                AuditId = $auditId.ToString()
                ResourceStates = $resourceStates
                ResourceIds = $resourceIds
                ResourceGroupName = $resourceGroupName
                DeploymentTemplate = $deploymentTemplate
                DeploymentParameters = $deploymentParameters
                DeploymentOutputs = $deploymentOutputs
                TenantId = $tenantId
                SubscriptionId = $subscriptionId
                Policies = $policies
                RBAC = $rbac
            }

            $this.stateRepository.SaveResourceState(
                $entity);

            $this.SaveResourceStateAndDeploymentNameMapping(
                $entity);
            
            return $stateId;
        }
        catch {
            Write-Host "An error ocurred while running ModuleStateDataService.SaveResourceState";
            Write-Host $_;
            throw $_;
        }
    }

    [object] GetResourceStateById([object] $stateId) {
        return $this.stateRepository.GetResourceStateById($stateId);
    }

    [object] GetResourceStateByFilters([object[]] $filters) {
        return $this.stateRepository.GetResourceStateByFilters($filters);
    }

    [object] GetResourceStateOutputs([string] $archetypeInstanceName, `
                                     [string] $moduleInstanceName) {
        try {
            # Setting initial filter object
            $filters = @(
                $archetypeInstanceName,
                $moduleInstanceName
            )

            # Let's get the deployment mapping object, this object contains
            # information about the latest resource state id and 
            # deployment id
            $deploymentMapping = `
                $this.stateRepository.GetLatestDeploymentMapping($filters);
            
            # If deploymentMapping is null, it means that there is no mapping found
            if (!$deploymentMapping) {
                Write-Host "No state information found";
                return $null;
            }
            else {
                # deployment mapping found, let's get the deployment outputs
                $filters += @(
                        $deploymentMapping.DeploymentName,
                        $deploymentMapping.StateId
                    );
                Write-Host "Filters: $(ConvertTo-Json $filters)";
                $resourceState = `
                    $this.stateRepository.GetResourceStateByFilters($filters);

                # return deployment outputs
                return $resourceState.DeploymentOutputs;
            }
        }
        catch {
            Write-Host "An error ocurred while running ModuleStateDataService.GetResourceStateOutputs";
            Write-Host $_;
            throw $_;
        }
        
    }

    [void] hidden SaveResourceStateAndDeploymentNameMapping([object] $entity) {
        try {
            $this.stateRepository.SaveResourceStateAndDeploymentNameMapping(
                $entity);
        }
        catch {
            Write-Host "An error ocurred while running ModuleStateDataService.UpdateResourceStateAndDeploymentIdMapping";
            Write-Host $_;
            throw $_;
        }
    }
}
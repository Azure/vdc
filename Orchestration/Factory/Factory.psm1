Class Factory {

    $container = @{};

    Factory([string]$auditStorageType,
            [string]$cacheStorageType,
            [string]$auditStoragePath) {
        Factory(
            $auditStorageType,
            $null,
            $null,
            $auditStoragePath,
            $cacheStorageType,
            $null);
    }

    Factory([string]$auditStorageType,
            [string]$auditStorageAccountName, 
            [string]$auditStorageAccountSasToken,
            [string]$auditStoragePath,
            [string]$cacheStorageType,
            [string]$deploymentServiceType) {
        
        $stateRepository = $null;
        $auditRepository = $null;
        $cacheRepository = $null;
        $cacheDataService = $null;

        if (![string]::IsNullOrEmpty($auditStorageType) -and `
            $auditStorageType.ToLower() -eq "storageaccount" `
            -and `
            ([string]::IsNullOrEmpty($auditStorageAccountName) -or `
             [string]::IsNullOrEmpty($auditStorageAccountSasToken)
            )
           ) {
            throw "Storage Account Name and Sas Token values required when Audit Storage Type is Storage Account";
        }

        if([string]::IsNullOrEmpty($auditStorageType)) {
            # Assumes local storage for now.
            if ([string]::IsNullOrEmpty($auditStoragePath)) {
                throw "Audit storage path is empty for local audit storage type, please provide a valid local storage path";
            }

            $stateRepository = `
                [LocalStorageStateRepository]::new($auditStoragePath);

            $auditRepository = `
                [LocalStorageAuditRepository]::new($auditStoragePath);
        }
        elseif($auditStorageType.ToLower().Equals("storageaccount", [StringComparison]::InvariantCultureIgnoreCase)) {
            $stateRepository = `
                [BlobContainerStateRepository]::new(
                    $auditStorageAccountName, 
                    $auditStorageAccountSasToken);

            $auditRepository = `
                [BlobContainerAuditRepository]::new(
                    $auditStorageAccountName, 
                    $auditStorageAccountSasToken);
        }
        else {
            throw "Not supported deployment service: $auditStorageType";
        }

        if([string]::IsNullOrEmpty($cacheStorageType)) {
            $cacheRepository = `
                [LocalCacheRepository]::new();
        }
        elseif($cacheStorageType.ToLower().Equals("azuredevops", [StringComparison]::InvariantCultureIgnoreCase)) {
            $cacheRepository = `
                [AzureDevOpsCacheRepository]::new();
        }
        else {
            throw "Not supported deployment service: $cacheStorageType";
        }

        $cacheDataService = `
                [CacheDataService]::new($cacheRepository);

        $moduleStateDataService = `
            [ModuleStateDataService]::new(
                $stateRepository);

        $deploymentAuditDataService = `
            [DeploymentAuditDataService]::new(
                $auditRepository);

        if ([string]::IsNullOrEmpty($deploymentServiceType)){
            $deploymentService = `
                [AzureResourceManagerDeploymentService]::new();
        }
        elseif($deploymentServiceType.ToLower().Equals("terraform", [StringComparison]::InvariantCultureIgnoreCase)) {
            Write-Debug "Deployment service found: $deploymentServiceType";
            $deploymentService = `
                [TerraformDeploymentService]::new();

            Write-Debug "Deployment service type is: "
        }
        else {
            throw "Not supported deployment service: $deploymentServiceType";
        }

        $tokenReplacementService = `
            [TokenReplacementService]::new();

        $customScriptExecution = `
            [CustomScriptExecution]::new();

        $this.container = @{
            IStateRepository = $stateRepository
            IAuditRepository = $auditRepository
            ICacheRepository = $cacheRepository
            ICacheDataService = $cacheDataService
            IDeploymentAuditDataService = $deploymentAuditDataService
            IModuleStateDataService = $moduleStateDataService
            IDeploymentService = $deploymentService
            ITokenReplacementService = $tokenReplacementService
            CustomScriptExecution = $customScriptExecution
        };
    }

    [object] GetInstance([object] $interfaceName) {
        return $this.container[$interfaceName];
    }
}
<#
    Function that acts as a wrapper allowing us to
    pass mandatory values only.
#>
Function New-FactoryInstance() {
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $AuditStorageType,
        [Parameter(Mandatory=$false)]
        [string] 
        $AuditStorageAccountName,
        [Parameter(Mandatory=$false)]
        [string] 
        $AuditStorageAccountSasToken,
        [Parameter(Mandatory=$false)]
        [string]
        $AuditStoragePath,
        [Parameter(Mandatory=$true)]
        [string] 
        $CacheStorageType,
        [Parameter(Mandatory=$true)]
        [string] 
        $DeploymentService
    )
    return [Factory]::new(
        $AuditStorageType,
        $AuditStorageAccountName, 
        $AuditStorageAccountSasToken,
        $AuditStoragePath,
        $CacheStorageType,
        $DeploymentService);
}
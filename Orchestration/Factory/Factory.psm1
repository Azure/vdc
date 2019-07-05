Class Factory {

    $container = @{};

    Factory([string]$auditStorageType,
            [string]$cacheStorageType,
            [string]$auditStoragePath) {
        Factory(
            $auditStorageType,
            $null,
            $null,
            $cacheStorageType,
            $auditStoragePath);
    }

    Factory([string]$auditStorageType,
            [string]$auditStorageAccountName, 
            [string]$auditStorageAccountSasToken,
            [string]$cacheStorageType,
            [string]$auditStoragePath) {
        
        $stateRepository = $null;
        $auditRepository = $null;
        $cacheRepository = $null;
        $cacheDataService = $null;

        if ($auditStorageType.ToLower() -eq "storageaccount" `
            -and `
            ([string]::IsNullOrEmpty($auditStorageAccountName) -or `
             [string]::IsNullOrEmpty($auditStorageAccountSasToken)
            )
           ) {
            throw "Storage Account Name and Sas Token values required when Audit Storage Type is Storage Account";
        }

        if($auditStorageType.ToLower() -eq "storageaccount") {
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
            # Assumes local storage for now.
            if ([string]::IsNullOrEmpty($auditStoragePath)) {
                throw "Audit storage path is empty for local audit storage type, please provide a valid local storage path";
            }

            $stateRepository = `
                [LocalStorageStateRepository]::new($auditStoragePath);

            $auditRepository = `
                [LocalStorageAuditRepository]::new($auditStoragePath);
        }

        if($cacheStorageType.ToLower() -eq "azuredevops") {
            $cacheRepository = `
                [AzureDevOpsCacheRepository]::new();
        }
        elseif ($cacheStorageType.ToLower() -eq "local" `
            -or [string]::IsNullOrEmpty($cacheStorageType) ) {
            $cacheRepository = `
                [LocalCacheRepository]::new();
        }

        $cacheDataService = `
                [CacheDataService]::new($cacheRepository);

        $moduleStateDataService = `
            [ModuleStateDataService]::new(
                $stateRepository);

        $deploymentAuditDataService = `
            [DeploymentAuditDataService]::new(
                $auditRepository);

        $deploymentService = `
            [AzureResourceManagerDeploymentService]::new();

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
        [Parameter(Mandatory=$true)]
        [string] 
        $CacheStorageType,
        [Parameter(Mandatory=$false)]
        [string]
        $AuditStoragePath
    )
    return [Factory]::new(
        $AuditStorageType,
        $AuditStorageAccountName, 
        $AuditStorageAccountSasToken,
        $CacheStorageType,
        $AuditStoragePath);
}
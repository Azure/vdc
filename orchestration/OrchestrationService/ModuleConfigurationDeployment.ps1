[CmdletBinding()]
    param (
    [Parameter(Mandatory=$false)]
    [string] 
    $ArchetypeInstanceName,
    [Parameter(Mandatory=$true)]
    [string] 
    $ArchetypeDefinitionPath,
    [Parameter(Mandatory=$true)]
    [string] 
    $ModuleConfigurationName,
    [Parameter(Mandatory=$false)]
    [string]
    $WorkingDirectory,
    [Parameter(Mandatory=$false)]
    [switch]
    $Validate)

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent;
$bootstrapModulePath = Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'Bootstrap') -ChildPath 'Initialize.psd1';
$scriptBlock = "using Module $bootstrapModulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$factoryModulePath = Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'Factory') -ChildPath 'Factory.psd1';
Import-Module $bootstrapModulePath -Force;
Import-Module $factoryModulePath -Force;
Import-Module "$($rootPath)/../Common/Helper.psd1" -Force;

$deploymentService = $null;
$cacheDataService = $null;
$auditDataService = $null;
$moduleStateDataService = $null;
$configurationBuilder = $null;
$factory = $null;
$defaultLocation = "West US";
$notSupportedVersion = 1.9;
$defaultSupportedVersion = 2.0;
$defaultModuleConfigurationsFolderName = "modules";
$defaultTemplateFileName = "deploy.json";
$defaultParametersFileName = "parameters.json";

        
Function New-Deployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string] 
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [string] 
        $ArchetypeDefinitionPath,
        [Parameter(Mandatory=$true)]
        [string] 
        $ModuleConfigurationName,
        [Parameter(Mandatory=$false)]
        [string]
        $WorkingDirectory,
        [Parameter(Mandatory=$false)]
        [switch]
        $Validate
        # WorkingDirectory is required to construct
        # modules folder, deployment and parameters file paths
        # when no value is specified. If no value is specified,
        # we assume that the folders and files will be
        # relative to the working directory (root of the repository).
        # WorkingDirectory is required when running the script
        # from a local computer.
    )
    try {
        
        $hostType = `
            Get-PowershellEnvironmentVariable `
                -Key "SYSTEM_HOSTTYPE";

        Write-Debug "Host type is: $hostType";

        $systemDefaultWorkingDirectory = `
            Get-PowershellEnvironmentVariable `
                -Key "SYSTEM_DEFAULTWORKINGDIRECTORY";

        Write-Debug "System default working directory is: `
            $systemDefaultWorkingDirectory";

        # Set the defaultWorkingDirectory
        if(![string]::IsNullOrEmpty($WorkingDirectory)) {
            Write-Debug "Working directory parameter passed: $WorkingDirectory";
            # If Working directory information is explicitly passed,
            # then set it
            $defaultWorkingDirectory = $WorkingDirectory;
        }
        elseif ($hostType -eq "build") {
            # If the environment is build environment, use the 
            # system_defaultworkingdirectory that is available in the pipeline

            $defaultWorkingDirectory = $systemDefaultWorkingDirectory;
        }
        # This is true when the running the script from Azure DevOps - release pipeline
        elseif ($hostType -eq "release"){
            # If the environment is release environment, use a combination of 
            # system_defaukltWorkingDirectory and the release_primaryArtifactSourceAlias

            $releasePrimaryArtifactSourceAlias = `
                Get-PowershellEnvironmentVariable `
                    -Key "RELEASE_PRIMARYARTIFACTSOURCEALIAS";

            $defaultWorkingDirectory = "$systemDefaultWorkingDirectory\$releasePrimaryArtifactSourceAlias"
        }
        # This is true when the running the script locally
        else {
            Write-Debug "Local deployment, attempting to resolve root path";
            # If no explicity working directory is passed and the script
            # is run locally, then use the current path
            $defaultWorkingDirectory = (Resolve-Path ".\").Path;
        }

        Write-Debug "Working directory is: $defaultWorkingDirectory";

        $factory = Invoke-Bootstrap;
        
        $deploymentService = `
            $factory.GetInstance('IDeploymentService');

        $cacheDataService = `
            $factory.GetInstance('ICacheDataService');

        $auditDataService = `
            $factory.GetInstance('IDeploymentAuditDataService');

        $moduleStateDataService = `
            $factory.GetInstance('IModuleStateDataService');

        $configurationBuilder = `
            $factory.GetInstance('ConfigurationBuilder');
        
        # Contruct the archetype instance object only if it is not already
        # cached
        $archetypeInstanceJson = `
            Build-ConfigurationInstance `
                -FilePath $ArchetypeDefinitionPath `
                -WorkingDirectory $defaultWorkingDirectory `
                -CacheKey $ArchetypeInstanceName;
                
        # Retrieve the Archetype instance name if not already passed
        # to this function
        $ArchetypeInstanceName = `
            Get-ArchetypeInstanceName `
                -ArchetypeInstance $archetypeInstanceJson `
                -ArchetypeInstanceName $ArchetypeInstanceName;

        $moduleConfiguration = `
            Get-ModuleConfiguration `
                -ArchetypeInstanceJson $archetypeInstanceJson `
                -ModuleConfigurationName $moduleConfigurationName;
        Write-Debug "Module instance configuration is: $(ConvertTo-Json $moduleConfiguration)";
        
        # Let's make sure we use the updated name
        # There are instances when we have a module configuration updating an existing
        # module configuration that was already deployed, in this case, let's use
        # the name of the existing module configuration. 
        Write-Debug "Updating module instance name from $ModuleConfigurationName to $($moduleConfiguration.Name)";
        $ModuleConfigurationName = `
            $moduleConfiguration.Name;

        $subscriptionInformation = $null;
        $subscriptionInformation = `
            Get-SubscriptionInformation `
                -ArchetypeInstanceJson $archetypeInstanceJson `
                -SubscriptionName $archetypeInstanceJson.ArchetypeParameters.Subscription `
                -ModuleConfiguration $moduleConfiguration;
        
        # Do not change the subscription context if the operation is validate.
        # This is because the script will expect the validation resource 
        # group to be present in all the subscriptions we are deploying.
        if(-not $Validate.IsPresent) {
            Write-Debug "Setting subscription context";

            Set-SubscriptionContext `
                -SubscriptionId $subscriptionInformation.SubscriptionId `
                -TenantId $subscriptionInformation.TenantId;
        }

        # Let's attempt to get the Audit Id from cache
        $auditCacheKey = `
                "{0}_AuditId" -f `
                $ArchetypeInstanceName;

        Write-Debug "Audit Id cache key is: $auditCacheKey";

        $auditId = `
            Get-ItemFromCache `
                -Key $auditCacheKey;
        
        Write-Debug "Audit Id from cache is: $auditId"
        
        # If no value is found, let's create 
        # deployment audit information and cache
        # the auditId value
        if ($null -eq $auditId) {
            # Store deployment audit information

            $auditInformation = `
                Get-AzureDevOpsAuditEnvironmentVariables;

            $auditId = `
                New-DeploymentAuditInformation `
                    -BuildId $auditInformation.BuildId `
                    -BuildName $auditInformation.BuildName `
                    -CommitId $auditInformation.CommitId `
                    -CommitMessage $auditInformation.CommitMessage `
                    -CommitUsername $auditInformation.CommitUsername `
                    -BuildQueuedBy $auditInformation.BuildQueuedBy `
                    -ReleaseId $auditInformation.ReleaseId `
                    -ReleaseName $auditInformation.ReleaseName `
                    -ReleaseRequestedFor $auditInformation.ReleaseRequestedFor `
                    -TenantId $subscriptionInformation.TenantId `
                    -SubscriptionId $subscriptionInformation.SubscriptionId `
                    -ArchetypeInstance $archetypeInstanceJson `
                    -ArchetypeInstanceName $ArchetypeInstanceName;
            Write-Debug "Audit trail created, Id: $($auditId.ToString())";
            
            Add-ItemToCache `
                -Key $auditCacheKey `
                -Value $auditId;
            Write-Debug "Audit Id succesfully cached.";
        }

        $moduleConfigurationResourceGroupName =
            Get-ResourceGroupName `
                -ArchetypeInstanceName $ArchetypeInstanceName `
                -ModuleConfiguration $moduleConfiguration;
        Write-Debug "Resource Group is: $moduleConfigurationResourceGroupName";
        
        New-ResourceGroup `
            -ResourceGroupName $moduleConfigurationResourceGroupName `
            -ResourceGroupLocation $subscriptionInformation.Location;
        Write-Debug "Resource Group successfully created";

        $moduleConfigurationPolicyDeploymentTemplate = `
            Get-PolicyDeploymentTemplateFileContents `
                -DeploymentConfiguration $moduleConfiguration.Policies `
                -ModuleConfigurationsPath $archetypeInstanceJson.ArchetypeOrchestration.ModuleConfigurationsPath `
                -WorkingDirectory $defaultWorkingDirectory;
        Write-Debug "Policy Deployment template contents is: $moduleConfigurationPolicyDeploymentTemplate";

        $moduleConfigurationPolicyDeploymentParameters = `
            Get-PolicyDeploymentParametersFileContents `
                -DeploymentConfiguration $moduleConfiguration.Policies `
                -ModuleConfigurationsPath $archetypeInstanceJson.ArchetypeOrchestration.ModuleConfigurationsPath `
                -WorkingDirectory $defaultWorkingDirectory;
        Write-Debug "Policy Deployment parameters contents is: $moduleConfigurationPolicyDeploymentParameters";

        $policyResourceState = @{};

        if ($null -ne $moduleConfigurationPolicyDeploymentTemplate) {
                Write-Debug "About to trigger a deployment";
                $policyResourceState = `
                Deploy-AzureResourceManagerTemplate `
                    -TenantId $subscriptionInformation.TenantId `
                    -SubscriptionId $subscriptionInformation.SubscriptionId `
                    -ResourceGroupName $moduleConfigurationResourceGroupName `
                    -DeploymentTemplate $moduleConfigurationPolicyDeploymentTemplate `
                    -DeploymentParameters $moduleConfigurationPolicyDeploymentParameters `
                    -Location $subscriptionInformation.Location `
                    -Validate:$($Validate.IsPresent);
                Write-Debug "Deployment complete, Resource state is: $(ConvertTo-Json -Compress $policyResourceState)";
        }
        else {
            Write-Debug "No Policy deployment";
        }

        $moduleConfigurationRBACDeploymentTemplate = `
            Get-RbacDeploymentTemplateFileContents `
                -DeploymentConfiguration $moduleConfiguration.RBAC `
                -ModuleConfigurationsPath $archetypeInstanceJson.ArchetypeOrchestration.ModuleConfigurationsPath `
                -WorkingDirectory $defaultWorkingDirectory;
        Write-Debug "RBAC Deployment template contents is: $moduleConfigurationRBACDeploymentTemplate";

        $moduleConfigurationRBACDeploymentParameters = `
            Get-RbacDeploymentParametersFileContents `
                -DeploymentConfiguration $moduleConfiguration.RBAC `
                -ModuleConfigurationsPath $archetypeInstanceJson.ArchetypeOrchestration.ModuleConfigurationsPath `
                -WorkingDirectory $defaultWorkingDirectory;
        Write-Debug "RBAC Deployment parameters contents is: $moduleConfigurationRBACDeploymentParameters";

        $rbacResourceState = @{};

        if ($null -ne $moduleConfigurationRBACDeploymentTemplate) {
            Write-Debug "About to trigger a deployment";
            $rbacResourceState = `
                Deploy-AzureResourceManagerTemplate `
                    -TenantId $subscriptionInformation.TenantId `
                    -SubscriptionId $subscriptionInformation.SubscriptionId `
                    -ResourceGroupName $moduleConfigurationResourceGroupName `
                    -DeploymentTemplate $moduleConfigurationRBACDeploymentTemplate `
                    -DeploymentParameters $moduleConfigurationRBACDeploymentParameters `
                    -Location $subscriptionInformation.Location `
                    -Validate:$($Validate.IsPresent);
            Write-Debug "Deployment complete, Resource state is: $(ConvertTo-Json -Compress $rbacResourceState)";
        }
        else {
            Write-Debug "No RBAC deployment";
        }

        $moduleConfigurationDeploymentTemplate = `
            Get-DeploymentTemplateFileContents `
                -DeploymentConfiguration $moduleConfiguration.Deployment `
                -ModuleConfigurationsPath $archetypeInstanceJson.ArchetypeOrchestration.ModuleConfigurationsPath `
                -WorkingDirectory $defaultWorkingDirectory;
        Write-Debug "Deployment template contents is: $moduleConfigurationDeploymentTemplate";

        $moduleConfigurationDeploymentParameters = `
            Get-DeploymentParametersFileContents `
                -DeploymentConfiguration $moduleConfiguration.Deployment `
                -ModuleConfigurationsPath $archetypeInstanceJson.ArchetypeOrchestration.ModuleConfigurationsPath `
                -WorkingDirectory $defaultWorkingDirectory;
        Write-Debug "Deployment parameters contents are: $moduleConfigurationDeploymentParameters";

        # Merge the template's parameters json file
        $moduleConfigurationDeploymentParameters = `
            Merge-Parameters `
                -DeploymentParameters $moduleConfigurationDeploymentParameters `
                -ModuleConfiguration $moduleConfiguration `
                -ArchetypeInstanceName $ArchetypeInstanceName `
                -Operation @{ "False" = "deploy"; "True" = "validate"; }[$Validate.ToString()];

        Write-Debug "Overridden parameters are: $moduleConfigurationDeploymentParameters";

        Write-Debug "About to trigger a deployment";
        $resourceState = `
            Deploy-AzureResourceManagerTemplate `
                -TenantId $subscriptionInformation.TenantId `
                -SubscriptionId $subscriptionInformation.SubscriptionId `
                -ResourceGroupName $moduleConfigurationResourceGroupName `
                -DeploymentTemplate $moduleConfigurationDeploymentTemplate `
                -DeploymentParameters $moduleConfigurationDeploymentParameters `
                -Location $subscriptionInformation.Location `
                -Validate:$($Validate.IsPresent);
        Write-Debug "Deployment complete, Resource state is: $(ConvertTo-Json -Compress $resourceState)";
        
        if(!$Validate.IsPresent) {
            # If there are deployment outputs, cache the values
            if ($null -ne $resourceState.DeploymentOutputs) {

                Add-OutputsToCache `
                    -ModuleConfigurationName $moduleConfigurationName `
                    -Outputs $resourceState.DeploymentOutputs;
            }

            # Store deployment state information
            $moduleStateId = `
                New-DeploymentStateInformation `
                    -AuditId $auditId `
                    -DeploymentId $resourceState.DeploymentId `
                    -DeploymentName $resourceState.DeploymentName `
                    -ArchetypeInstanceName $ArchetypeInstanceName `
                    -ModuleConfigurationName $moduleConfigurationName `
                    -ResourceStates $resourceState.ResourceStates `
                    -ResourceIds $resourceState.ResourceIds `
                    -ResourceGroupName $resourceState.ResourceGroupName `
                    -DeploymentTemplate $resourceState.DeploymentTemplate `
                    -DeploymentParameters $resourceState.DeploymentParameters `
                    -DeploymentOutputs $resourceState.DeploymentOutputs `
                    -TenantId $subscriptionInformation.TenantId `
                    -SubscriptionId $subscriptionInformation.SubscriptionId `
                    -Policies $policyResourceState `
                    -RBAC $rbacResourceState;
            Write-Debug "Module state created, Id: $($moduleStateId.ToString())";
        }
    }
    catch {
        Write-Host "An error ocurred while running New-Deployment";
        Write-Host $_;
        throw $_;
    }
}

Function Get-ArchetypeInstanceName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ArchetypeInstance,
        [Parameter(Mandatory=$false)]
        [string]
        $ArchetypeInstanceName
    )

    try {
        if ([string]::IsNullOrEmpty($ArchetypeInstanceName)) {
            Write-Debug "Archetype instance name not provided as input parameter, attempting to retrieve it from ArchetypeParameters.InstanceName";

            if ($null -eq $ArchetypeInstance.ArchetypeParameters.InstanceName -or `
                [string]::IsNullOrEmpty($ArchetypeInstance.ArchetypeParameters.InstanceName)) {
                throw "Archetype instance name not provided as input parameter or in ArchetypeParameters.InstanceName";
            }

            return $ArchetypeInstance.ArchetypeParameters.InstanceName;
        }
        else {
            return $ArchetypeInstanceName;
        }
    }
    catch {
        Write-Host "An error ocurred while running Get-ArchetypeInstanceName";
        Write-Host $_;
        throw $_;
    }
}

Function Set-SubscriptionContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $SubscriptionId,
        [Parameter(Mandatory=$true)]
        [string]
        $TenantId
    )

    try {
        $deploymentService.SetSubscriptionContext(
            $SubscriptionId,
            $TenantId);
    }
    catch {
        Write-Host "An error ocurred while running Set-SubscriptionContext";
        Write-Host $_;
        throw $_;
    }
    
}
Function Build-ConfigurationInstance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $FilePath,
        [Parameter(Mandatory=$true)]
        [string]
        $WorkingDirectory,
        [Parameter(Mandatory=$false)]
        [string]
        $CacheKey
    )

    try {
        # First, retrieve the value from the cache
        # If a value exists, it is going to be a
        # hashtable in this case.
        $configurationInstance = $null;

        if(![string]::IsNullOrEmpty($CacheKey)) {
            $configurationInstance = $cacheDataService.GetByKey($CacheKey);
        }
        Write-Debug "Configuration instance found: $($null -ne $configurationInstance)";
        
        if($null -eq $configurationInstance) {
            Write-Debug "No configuration instance found in the cache, generating one";
            
            # Let's get the absolute path, if an absolute path is passed
            # as part of FilePath, then this function
            # returns the value as is.
            $FilePath = `
                ConvertTo-AbsolutePath `
                    -Path $FilePath `
                    -RootPath $WorkingDirectory;
            
            Write-Debug "File path: $FilePath";

            $configurationBuilder = [ConfigurationBuilder]::new(
                $null,
                $FilePath
            );
            
            # Generate archetype Instance from archetype 
            # definition
            $configurationInstance = `
                $configurationBuilder.BuildConfigurationInstance();
            Write-Debug "Configuration instance: $(ConvertTo-Json $configurationInstance -Depth 100)"

            if(![string]::IsNullOrEmpty($CacheKey)) {
                # Let's cache the archetype instance
                $cacheDataService.SetByKey(
                    $CacheKey,
                    $configurationInstance);
            }

            Write-Debug "Configuration instance properly cached, using key: $ArchetypeInstanceName";
        }
        return $configurationInstance;
    }
    catch {
        Write-Host "An error ocurred while running Build-ConfigurationInstance";
        Write-Host $_;
        throw $_;
    }
}

Function Invoke-Bootstrap {
    [CmdletBinding()]
    param ()

    $toolkitConfigurationFileName = "toolkit.config.json";

    try {
        # Build toolkit configuration from file
        $toolkitConfigurationJson = `
            Build-ConfigurationInstance `
                -FilePath $toolkitConfigurationFileName `
                -WorkingDirectory $defaultWorkingDirectory;

        # Getting cache information from toolkit configuration
        $cacheStorageInformation = `
            Get-CacheStorageInformation `
                -ToolkitConfigurationJson $toolkitConfigurationJson;

        Write-Debug "Cache storage information is: $(ConvertTo-Json $cacheStorageInformation -Depth 100)";

        # Getting audit information from toolkit configuration
        $auditStorageInformation = `
            Get-AuditStorageInformation `
                -ToolkitConfigurationJson $toolkitConfigurationJson;

        Write-Debug "Audit storage information is: $(ConvertTo-Json $auditStorageInformation -Depth 100)";

        # Let's create a new instance of Bootstrap
        $bootstrap = [Initialize]::new();
                
        # Let's initialize the appropriate storage type
        if ($auditStorageInformation.StorageType.ToLower() `
            -eq "storageaccount") {
            $bootstrapResults = `
                $bootstrap.InitializeStorageAccountStore(
                    $auditStorageInformation.TenantId,
                    $auditStorageInformation.SubscriptionId,
                    $auditStorageInformation.ResourceGroup,
                    $auditStorageInformation.Location,
                    $auditStorageInformation.StorageAccountName);

            $factory = `
                New-FactoryInstance `
                    -AuditStorageType $auditStorageInformation.StorageType `
                    -AuditStorageAccountName $bootstrapResults.StorageAccountName `
                    -AuditStorageAccountSasToken $bootstrapResults.StorageAccountSasToken `
                    -CacheStorageType $cacheStorageInformation.StorageType;
            
            Write-Debug "Bootstrap type: storage account, result is: $(ConvertTo-Json $bootstrapResults -Depth 100)";
        }
        elseif ($auditStorageInformation.StorageType.ToLower() `
                -eq "local") {
            $bootstrapResults = `
                $bootstrap.InitializeLocalStore();

            $factory = `
                New-FactoryInstance `
                    -AuditStorageType $auditStorageInformation.StorageType `
                    -CacheStorageType $cacheStorageInformation.StorageType;
            
            Write-Debug "Bootstrap type: local storage, result is: $(ConvertTo-Json $bootstrapResults -Depth 100)";
        }
        # Not supported, throw an error
        else {
            throw "ToolkitComponents.Audit.StorageType not supported, currently supported types are: StorageAccount and Local";
        }

        return $factory;
    }
    catch {
        Write-Host "An error ocurred while running Invoke-Bootstrap";
        Write-Host $_;
        throw $_;
    }
}

Function Get-SubscriptionInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable] 
        $ArchetypeInstanceJson,
        [Parameter(Mandatory=$true)]
        [string] 
        $SubscriptionName,
        [Parameter(Mandatory=$false)]
        [hashtable]
        $ModuleConfiguration
    )

    try {
        # Hashtables ArchetypeInstanceJson and ModuleConfiguration are case-sensitive.
        # To retrieve the properties without having to pass the exact case-sensitive value,
        # we pass the case-insensitive key, match it with the set of available keys in the 
        # Hashtable and return a case-sensitive version of that same key to be used later to
        # retrieve the Subscription Information.
        if($ArchetypeInstanceJson.Keys -match "subscriptions") {
            # Match operation always returns an array. We retrieve the first item in the array.
            # The retrieved item represents the case-sensitive version of the key.
            $archetypeInstanceSubscriptions = ($ArchetypeInstanceJson.Keys -match "subscriptions")[0];
        }
        if($ModuleConfiguration.Keys -match "subscription") {
            # Match operation always returns an array. We retrieve the first item in the array.
            # The retrieved item represents the case-sensitive version of the key.
            $subscriptionKey = ($ModuleConfiguration.Keys -match "subscription")[0];
        }
        
        $subscriptionInformation = $null;

        Write-Debug "Let's check if module configuration is not null and has a Subscription property with a value different than null or empty.";
        if (($null -ne $ModuleConfiguration) -and `
            $null -ne $subscriptionKey -and `
            ![string]::IsNullOrEmpty($ModuleConfiguration.$subscriptionKey)) {
            Write-Debug "Module instance configuration found and has a Subscription property, will use its values to run a deployment.";
            Write-Debug "Subscription name is: $($moduleConfiguration.$subscriptionKey)";

            $SubscriptionName = `
                $moduleConfiguration.$subscriptionKey;
        }

        $subscriptionNameMatch = $ArchetypeInstanceJson.$archetypeInstanceSubscriptions.Keys -match $SubscriptionName;
        if($archetypeInstanceSubscriptions `
            -and $subscriptionNameMatch) {
            # Retrieve case-sensitive key name from case-insensitive key name using match operation
            $SubscriptionName = $subscriptionNameMatch[0];
            $subscriptionInformation = `
                $archetypeInstanceJson.$archetypeInstanceSubscriptions.$SubscriptionName;
        }

        $locationMatch = $subscriptionInformation.Keys -match "location";
        # First, make sure the location key is present itn the subscriptionInformation hashtable
        if($locationMatch) {
            # Retrieve case-sensitive key name from case-insensitive key name using match operation
            $location = $locationMatch[0];
            # Then proceed to check if the location properties is present in the subscriptionInformation
            if($null -eq $subscriptionInformation.$location) {
                Write-Debug "Deployment location not found, using default location: $defaultLocation";
                # $defaultLocation is a global variable
                $subscriptionInformation.$location = `
                    $defaultLocation;
            }
        }
        Write-Debug "Subscription information is: $(ConvertTo-Json $subscriptionInformation)";
        return $subscriptionInformation;
    }
    catch {
        Write-Host "An error ocurred while running Get-SubscriptionInformation";
        Write-Host $_;
        throw $_;
    }
}

Function Get-CacheStorageInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable] 
        $ToolkitConfigurationJson
    )

    try {
        $cacheStorageInformation = @{
            StorageType = ''
        };

        if ($ToolkitConfigurationJson.Configuration.Cache -and
            $ToolkitConfigurationJson.Configuration.Cache.StorageType.ToLower() -eq "azuredevops") {
            
            # Let's get the Storage Type information
            $cacheStorageInformation.StorageType = 'azuredevops';
        }
        # Let's get audit local storage information
        elseif(($ToolkitConfigurationJson.Configuration.Cache -and
            $ToolkitConfigurationJson.Configuration.Cache.StorageType.ToLower() -eq "local") -or
            $null -ne $ToolkitConfigurationJson -or 
            $null -eq $ToolkitConfigurationJson.Configuration -or
            $null -eq $ToolkitConfigurationJson.Configuration.Cache -or
            $null -eq $ToolkitConfigurationJson.Configuration.Cache.StorageType) {
            $cacheStorageInformation.StorageType = 'local';
        }
        # Not supported error
        else {
            throw "Configuration.Cache object not present or Cache.StorageType not supported, currently supported types are: AzureDevOps and Local";
        }
        return $cacheStorageInformation;
    }
    catch {
        Write-Host "An error ocurred while running Get-CacheStorageInformation";
        Write-Host $_;
        throw $_;
    }
}

Function Get-AuditStorageInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable] 
        $ToolkitConfigurationJson
    )
    try {
        $auditStorageInformation = @{
            StorageType = ''
            TenantId = ''
            SubscriptionId = ''
            ResourceGroup = ''
            Location = ''
            StorageAccountName = ''
            LocalPath = ''
        };

        if ($ToolkitConfigurationJson.Configuration.Audit -and
        $ToolkitConfigurationJson.Configuration.Audit.StorageType.ToLower() -eq "storageaccount"){
            
            # Let's get the Storage Account information, this information will be used
            # when provisioning an Audit Storage Account.
            $auditStorageInformation.StorageType = 'storageaccount';
            $auditStorageInformation.TenantId = `
                $ToolkitConfigurationJson.Subscription.TenantId;
            $auditStorageInformation.SubscriptionId = `
                $ToolkitConfigurationJson.Subscription.SubscriptionId;
            $auditStorageInformation.ResourceGroup = `
                $ToolkitConfigurationJson.Configuration.Audit.ResourceGroup;
            $auditStorageInformation.Location = `
                $ToolkitConfigurationJson.Subscription.Location;
            $auditStorageInformation.StorageAccountName = `
                $ToolkitConfigurationJson.Configuration.Audit.StorageAccountName;
            
            # Let's check for invariant information.
            if ([string]::IsNullOrEmpty($auditStorageInformation.TenantId) -or 
                [string]::IsNullOrEmpty($auditStorageInformation.SubscriptionId) -or 
                [string]::IsNullOrEmpty($auditStorageInformation.ResourceGroup) -or 
                [string]::IsNullOrEmpty($auditStorageInformation.Location)) {
                    throw "TenantId, SubscriptionId, ResourceGroup and Location are required values when using a Audit.StorageType equals to StorageAccount."
                }
        }
        # Let's get audit local storage information
        elseif (($ToolkitConfigurationJson.Configuration.Audit -and
                $ToolkitConfigurationJson.Configuration.Audit.StorageType.ToLower() -eq "local") -or
                $null -ne $ToolkitConfigurationJson -or 
                $null -ne $ToolkitConfigurationJson.Configuration -or 
                $null -ne $ToolkitConfigurationJson.Configuration.Audit -or 
                $null -ne $ToolkitConfigurationJson.Configuration.Audit.StorageType) {
            
            $auditStorageInformation.StorageType = 'local';
            if($null -ne $ToolkitConfigurationJson.Configuration.Audit.LocalPath) {
                # This path is optional, you can provide a specific path where all the audit information will get
                # saved.
                $auditStorageInformation.LocalPath = `
                    $ToolkitConfigurationJson.Configuration.Audit.LocalPath;
            }
            else {
                # This path is optional, you can provide a specific path where all the audit information will get
                # saved.
                $auditStorageInformation.LocalPath = `
                    $defaultWorkingDirectory;
            }
        }
        # Not supported error
        else {
            throw "Configuration.Audit object not present or Audit.StorageType not supported, currently supported types are: StorageAccount and Local";
        }
        return $auditStorageInformation;
    }
    catch {
        Write-Host "An error ocurred while running Get-AuditStorageInformation";
        Write-Host $_;
        throw $_;
    }
}

Function Get-ModuleConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable] 
        $ArchetypeInstanceJson,
        [Parameter(Mandatory=$true)]
        [string] 
        $ModuleConfigurationName
    )

    try {
        Write-Debug "About to search for Module Instance Name: $ModuleConfigurationName";
        $moduleConfiguration = `
            $ArchetypeInstanceJson.ArchetypeOrchestration.ModuleConfigurations | Where-Object -Property 'Name' -EQ $moduleConfigurationName;

        if ($null -ne $moduleConfiguration){
            Write-Debug "Module instance configuration found: $(ConvertTo-Json $moduleConfiguration -Depth 100)";

            # Let's check if we are updating an existing module
            if ($null -ne $moduleConfiguration.Updates) {
                
                $existingModuleConfigurationName = `
                    $moduleConfiguration.Updates;

                Write-Debug "Updating existing module: $existingModuleConfigurationName";

                # Let's check if the existing module exists:
                $existingModuleConfiguration = `
                    $ArchetypeInstanceJson.ArchetypeOrchestration.ModuleConfigurations | Where-Object -Property 'Name' -EQ $existingModuleConfigurationName;
                
                if ($null -eq $existingModuleConfiguration) {
                    throw "Existing module not found";
                }

                Write-Debug "Existing module found: $(ConvertTo-Json $existingModuleConfiguration -Depth 50)";

                $moduleConfiguration = `
                    Merge-ExistingModuleWithUpdatesModule `
                        -ModuleConfiguration $moduleConfiguration `
                        -ExistingModuleConfiguration $existingModuleConfiguration
            }
            return $moduleConfiguration;
        }
        else {
            Write-Debug "Module instance configuration not found";
            return $null;
        }
    }
    catch {
        Write-Host "An error ocurred while running Get-ModuleConfiguration";
        Write-Host $_;
        throw $_;
    }
}

Function Merge-ExistingModuleWithUpdatesModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ModuleConfiguration,
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ExistingModuleConfiguration
    )
    try {
        # If ModuleConfiguration.OverrideParameters properties exist
        # in ExistingModuleConfiguration.OverrideParameters, let's
        # update its contents, else append the property
        # to ExistingModuleConfiguration.OverrideParameters

        $existingModuleConfigurationName = `
            $ExistingModuleConfiguration.Name;

        Write-Debug "Updating module configuration name from $($ModuleConfiguration.Name) to $($ExistingModuleConfiguration.Name)"

        $existingOverrideParameters = `
            $ExistingModuleConfiguration.Deployment.OverrideParameters;

        $overrideParameters = `
            $ModuleConfiguration.Deployment.OverrideParameters;
        
        Write-Debug "Checking for override parameters";

        foreach($key in $overrideParameters.Keys) {
            if ($null -ne $existingOverrideParameters.$key) {
                Write-Debug "Found existing key: $key in module configuration: $existingModuleConfigurationName, updating its contents from: $($existingOverrideParameters.$key) to $($overrideParameters.$key)";
                $existingOverrideParameters.$key = `
                    $overrideParameters.$key;
            }
            else {
                Write-Debug "Appending new property";
                $existingOverrideParameters.$key = `
                    $overrideParameters.$key;
            }
        }

        Write-Debug "Updated module configuration: $(ConvertTo-Json $ExistingModuleConfiguration -Depth 50)";

        return $ExistingModuleConfiguration;
    }
    catch {
        Write-Host "An error ocurred while running Merge-ExistingModuleWithUpdatesModulez";
        Write-Host $_;
        throw $_;
    }
}

Function Get-PolicyDeploymentTemplateFileContents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable] 
        $DeploymentConfiguration,
        [Parameter(Mandatory=$false)]
        [string] 
        $ModuleConfigurationsPath,
        [Parameter(Mandatory=$true)]
        [string] 
        $WorkingDirectory
    )

    try {
        Write-Debug "Getting Policy template contents";

        return `
            Get-DeploymentFileContents `
                -DeploymentConfiguration $DeploymentConfiguration `
                -DeploymentType "Policies" `
                -DeploymentFileType "template" `
                -ModuleConfigurationsPath $ModuleConfigurationsPath `
                -WorkingDirectory $WorkingDirectory;
    }
    catch {
        Write-Host "An error ocurred while running Get-PolicyDeploymentTemplateFileContents";
        Write-Host $_;
        throw $_;
    }
}

Function Get-PolicyDeploymentParametersFileContents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable] 
        $DeploymentConfiguration,
        [Parameter(Mandatory=$false)]
        [string] 
        $ModuleConfigurationsPath,
        [Parameter(Mandatory=$true)]
        [string] 
        $WorkingDirectory
    )

    try {
        Write-Debug "Getting Policy parameters contents";

        return `
            Get-DeploymentFileContents `
                -DeploymentConfiguration $DeploymentConfiguration `
                -DeploymentType "Policies" `
                -DeploymentFileType "parameters" `
                -ModuleConfigurationsPath $ModuleConfigurationsPath `
                -WorkingDirectory $WorkingDirectory;
    }
    catch {
        Write-Host "An error ocurred while running Get-PolicyDeploymentParametersFileContents";
        Write-Host $_;
        throw $_;
    }
}

Function Get-RbacDeploymentTemplateFileContents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable] 
        $DeploymentConfiguration,
        [Parameter(Mandatory=$false)]
        [string] 
        $ModuleConfigurationsPath,
        [Parameter(Mandatory=$true)]
        [string] 
        $WorkingDirectory
    )
    
    try {
        Write-Debug "Getting RBAC template contents";

        $moduleDefinitionsRootPath = `
            Get-ParentFolder `
                -Path $ArchetypeDefinitionPath;

        return `
            Get-DeploymentFileContents `
                -DeploymentConfiguration $DeploymentConfiguration `
                -DeploymentType "RBAC" `
                -DeploymentFileType "template" `
                -ModuleConfigurationsPath $ModuleConfigurationsPath `
                -WorkingDirectory $WorkingDirectory
    }
    catch {
        Write-Host "An error ocurred while running Get-RbacDeploymentTemplateFileContents";
        Write-Host $_;
        throw $_;
    }
}

Function Get-RbacDeploymentParametersFileContents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable] 
        $DeploymentConfiguration,
        [Parameter(Mandatory=$false)]
        [string] 
        $ModuleConfigurationsPath,
        [Parameter(Mandatory=$true)]
        [string] 
        $WorkingDirectory
    )

    try {

        Write-Debug "Getting RBAC parameters contents";

        return `
            Get-DeploymentFileContents `
                -DeploymentConfiguration $DeploymentConfiguration `
                -DeploymentType "RBAC" `
                -DeploymentFileType "parameters" `
                -ModuleConfigurationsPath $ModuleConfigurationsPath `
                -WorkingDirectory $WorkingDirectory;
    }
    catch {
        Write-Host "An error ocurred while running Get-RbacDeploymentParametersFileContents";
        Write-Host $_;
        throw $_;
    }
}

Function Get-DeploymentTemplateFileContents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable] 
        $DeploymentConfiguration,
        [Parameter(Mandatory=$false)]
        [string] 
        $ModuleConfigurationsPath,
        [Parameter(Mandatory=$true)]
        [string] 
        $WorkingDirectory
    )

    try {
        Write-Debug "Getting Deployment template contents";

        # TODO: Can DeploymentFileType be an ENUM? `
        return `
            Get-DeploymentFileContents `
                -DeploymentConfiguration $DeploymentConfiguration `
                -DeploymentType "ARM" `
                -DeploymentFileType "template" `
                -ModuleConfigurationsPath $ModuleConfigurationsPath `
                -WorkingDirectory $WorkingDirectory;
    }
    catch {
        Write-Host "An error ocurred while running Get-DeploymentTemplateFileContents";
        Write-Host $_;
        throw $_;
    }
}

Function Get-DeploymentParametersFileContents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable] 
        $DeploymentConfiguration,
        [Parameter(Mandatory=$false)]
        [string] 
        $ModuleConfigurationsPath,
        [Parameter(Mandatory=$true)]
        [string] 
        $WorkingDirectory
    )

    try {
        Write-Debug "Getting Deployment parameters contents";

        # TODO: Can DeploymentFileType be an ENUM? `
        return `
            Get-DeploymentFileContents `
                -DeploymentConfiguration $DeploymentConfiguration `
                -DeploymentType "ARM" `
                -DeploymentFileType "parameters" `
                -ModuleConfigurationsPath $ModuleConfigurationsPath `
                -WorkingDirectory $WorkingDirectory;
    }
    catch {
        Write-Host "An error ocurred while running Get-DeploymentParametersFileContents";
        Write-Host $_;
        throw $_;
    }
}

Function Get-ModuleConfigurationsRootPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable] 
        $ModuleConfigurations,
        [Parameter(Mandatory=$true)]
        [string]
        $WorkingDirectory
    )
    try {
        $defaultModuleConfigurationsFolder = "modules";

        if([string]::IsNullOrEmpty(
            $ModuleConfigurations.ModuleConfigurationsRootPath)) {
                Write-Debug "No ModuleConfigurationsRootPath property found or is equals to empty, using default relative path: $defaultModuleConfigurationsFolder";
        }
    }
    catch {
        Write-Host "An error ocurred while running Get-ModuleConfigurationRootPath";
        Write-Host $_;
        throw $_;
    }
}

Function Get-DeploymentFileContents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [hashtable] 
        $DeploymentConfiguration,
        [Parameter(Mandatory=$true)]
        [string] 
        $DeploymentType, # TODO: Can this be an ENUM? Possible values are ARM, Policies, RBAC
        [Parameter(Mandatory=$true)]
        [string]
        $DeploymentFileType, # TODO: Is this the right name for TemplatePath or ParametersPath?
        [Parameter(Mandatory=$false)]
        [string] 
        $ModuleConfigurationsPath,
        [Parameter(Mandatory=$true)]
        [string] 
        $WorkingDirectory
    )

    try {

        # If there is no deployment configuration for
        # Policy or RBAC, return $null.
        # Deployment configuration must come when running
        # a resource deployment -> ARM deploymentType.

        Write-Debug "Deployment configuration is: $(ConvertTo-Json $DeploymentConfiguration)";
        Write-Debug "Deployment type is: $DeploymentType";

        if($null -eq $DeploymentConfiguration){
            Write-Debug "Deployment configuration doesn't exist for deployment type: $DeploymentType, creating default value";
            $DeploymentConfiguration = @{
                TemplatePath = $null
                ParametersPath = $null
            }
        }
        
        if ([string]::IsNullOrEmpty($ModuleConfigurationsPath)) {
            Write-Debug "Module configurations path not passed, creating a default one";
            $ModuleConfigurationsPath = `
                Join-Path $WorkingDirectory $defaultModuleConfigurationsFolderName

            Write-Debug "Default module configurations path is: $ModuleConfigurationsPath";
        }

        $deploymentFilePath = '';

        # There are only 2 options, $DeploymentFileType can be either a 
        # template or parameters
        if ($DeploymentFileType.ToLower() -eq "template") {
            Write-Debug "Retrieving Template information."
            # Let's get the template path, if no property exists,
            # the assigned value will be $null
            $deploymentFilePath = `
                $DeploymentConfiguration.TemplatePath;
            # Let's set a default file name
            $fileName = $defaultTemplateFileName;
        }
        else {
            Write-Debug "Retrieving Parameters information."
            # Let's get the parameters path, if no property exists,
            # the assigned value will be $null
            $deploymentFilePath = `
                $DeploymentConfiguration.ParametersPath;
            # Let's set a default file name
            $fileName = $defaultParametersFileName;
        }

        # If TemplatePath parameter exists, read its content
        if(![string]::IsNullOrEmpty($deploymentFilePath)){

            Write-Debug "Deployment file path found: $deploymentFilePath";
            return Get-Content $deploymentFilePath -Raw;
        }
        else {
            Write-Debug "Deployment file not found, creating a default one";
            Write-Debug "Module configurations folder name is: $defaultModuleConfigurationsFolderName";

            # Let's get the module configuration version
            $moduleConfigurationVersion = `
                Get-ModuleConfigurationVersion `
                    -ModuleConfiguration $ModuleConfiguration `
                    -ModuleConfigurationsPath $ModuleConfigurationsPath;
            
            # Let's create a relative path using forward slash delimiter
            $moduleConfigurationRelativePath = `
                "$($ModuleConfiguration.ModuleDefinitionName)/$moduleConfigurationVersion";

            Write-Debug "New module configuration relative path, including version is: $moduleConfigurationRelativePath";
            
            if ($DeploymentType.ToLower() -eq "arm") {
                $moduleConfigurationRelativePath += "/$fileName";
            }
            elseif ($DeploymentType.ToLower() -eq "policies") {
                $moduleConfigurationRelativePath += "/Policy/$fileName";
            }
            elseif ($DeploymentType.ToLower() -eq "rbac") {
                $moduleConfigurationRelativePath += "/RBAC/$fileName";
            }
            else {
                throw "Deployment type not supported";
            }

            # Let's get a relative template path that is OS agnostic
            # We'll split based on slashes because it is our internal
            # delimiter for folders plus file name
            $normalizedRelativeFilePath = `
                New-NormalizePath `
                    -FilePaths $moduleConfigurationRelativePath.Split('/');

            Write-Debug "Normalized relative path: $normalizedRelativeFilePath";
            # Finally let's get an absolute path by combining the
            # working directory ($WorkingDirectory) plus
            # $templatePath.

            $absoluteTemplatePath = `
                Join-Path $ModuleConfigurationsPath $normalizedRelativeFilePath;
            
            Write-Debug "Absolute path: $absoluteTemplatePath";

            # Check if the file exists
            $fileExists = Test-Path -Path $absoluteTemplatePath;
            if(!$fileExists) {
                Write-Debug "File $absoluteTemplatePath, for Type: $DeploymentType, does not exists";
                Write-Debug "Returning null so the deployment doesn't get executed";
                return $null;
            }
            # Get the file contents
            return Get-Content $absoluteTemplatePath -Raw;
        }
    }
    catch {
        Write-Host "An error ocurred while running Get-DeploymentFileContents";
        Write-Host $_;
        throw $_;
    }
}

Function Get-ModuleConfigurationVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ModuleConfiguration,
        [Parameter(Mandatory=$true)]
        [string]
        $ModuleConfigurationsPath

    )

    try {
        Write-Debug "ModuleConfiguration is: $(ConvertTo-Json $ModuleConfiguration)";
        Write-Debug "ModuleConfigurationsPath is: $ModuleConfigurationsPath";

        $currentVersion = $ModuleConfiguration.Version;

        if ([string]::IsNullOrEmpty($currentVersion)) {
            Write-Debug "Version property not found, sorting all version folders in desc order and grabbing the first item";
            # Let's read all folders inside the module configuration

            # Let's Join-Path moduleConfigurationsPath and moduleConfiguration
            $absolutePath = `
                Join-Path $ModuleConfigurationsPath $ModuleConfiguration.ModuleDefinitionName
            Write-Debug "Attempting to get all folders from: $absolutePath";
            
            $currentVersionFolder = `
                (Get-ChildItem `
                    -Path $absolutePath `
                    -Directory | `
                 Sort-Object `
                    -Property Name `
                    -Descending | `
                 Select-Object `
                    -First 1 `
                    -ErrorAction SilentlyContinue);

            if ($null -eq $currentVersionFolder) {
                Write-Debug "No folders found, using default version: $defaultSupportedVersion";
                $currentVersion = $defaultSupportedVersion;
            }
            else {
                $currentVersion = $currentVersionFolder.Name;
            }

            Write-Debug "Current module configuration version is: $currentVersion";
        }

        if ($currentVersion -le $defaultSupportedVersion) {
            throw "Not supported version, version retrieved is: $currentVersion. Supported versions are $defaultSupportedVersion and up.";
        }
        
        return $currentVersion;
    }
    catch {
        Write-Host "An error ocurred while running Get-ModuleConfigurationVersion";
        Write-Host $_;
        throw $_;
    }
}

Function Get-ResourceGroupName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] 
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [hashtable] 
        $ModuleConfiguration
    )

    try {
        $defaultResourceGroupName = "$($archetypeInstanceName)-$($moduleConfiguration.Name)-rg";
        $resourceGroupName = $moduleConfiguration.ResourceGroupName;
        if ($null -ne $resourceGroupName) {
            Write-Debug "Resource group property found: $($resourceGroupName)";
            return $resourceGroupName;
        }
        else {
            Write-Debug "Resource group property not found, creating default name: $($defaultResourceGroupName)";
            return $defaultResourceGroupName;
        }
    }
    catch {
        Write-Host "An error ocurred while running Get-ResourceGroupName";
        Write-Host $_;
        throw $_;
    }
}

Function New-ResourceGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] 
        $ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string] 
        $ResourceGroupLocation
    )

    try {
        $deploymentService.CreateResourceGroup(
            $resourceGroupName,
            $resourceGroupLocation);
    }
    catch {
        Write-Host "An error ocurred while running New-ResourceGroup";
        Write-Host $_;
        throw $_;
    }
}

Function Deploy-AzureResourceManagerTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [guid] 
        $TenantId,
        [Parameter(Mandatory=$true)]
        [guid] 
        $SubscriptionId,
        [Parameter(Mandatory=$true)]
        [string] 
        $ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string] 
        $DeploymentTemplate,
        [Parameter(Mandatory=$false)]
        [string] 
        $DeploymentParameters,
        [Parameter(Mandatory=$true)]
        [string] 
        $Location,
        [Parameter(Mandatory=$true)]
        [switch] 
        $Validate
    )
    
    try {
        if($Validate.IsPresent) { 
            Write-Debug "Validating the template";

            return `
                $deploymentService.ExecuteValidation(
                    $TenantId,
                    $SubscriptionId,
                    $defaultValidationResourceGroupName,
                    $DeploymentTemplate,
                    $DeploymentParameters,
                    $Location);
        }
        else {
            Write-Debug "Deploying the template";
            return `
                $deploymentService.ExecuteDeployment(
                    $TenantId,
                    $SubscriptionId,
                    $ResourceGroupName,
                    $DeploymentTemplate,
                    $DeploymentParameters,
                    $Location);
        }
    }
    catch {
        Write-Host "An error ocurred while running ModuleConfigurationDeployment.Deploy-AzureResourceManagerTemplate";
        Write-Host $_;
        throw $_;
    }
}

Function New-DeploymentStateInformation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [guid]
        $AuditId,
        [Parameter(Mandatory=$true)]
        [string]
        $DeploymentId,
        [Parameter(Mandatory=$true)]
        [string]
        $DeploymentName,
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [string]
        $ModuleConfigurationName,
        [Parameter(Mandatory=$true)]
        [object]
        $ResourceStates,
        [Parameter(Mandatory=$true)]
        [object]
        $ResourceIds,
        [Parameter(Mandatory=$true)]
        [string]
        $ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [object]
        $DeploymentTemplate,
        [Parameter(Mandatory=$true)]
        [object]
        $DeploymentParameters,
        [Parameter(Mandatory=$false)]
        [object]
        $DeploymentOutputs,
        [Parameter(Mandatory=$true)]
        [guid]
        $TenantId,
        [Parameter(Mandatory=$true)]
        [guid]
        $SubscriptionId,
        [Parameter(Mandatory=$false)]
        [object]
        $Policies,
        [Parameter(Mandatory=$false)]
        [object]
        $RBAC
    )
    try {
        return `
            $moduleStateDataService.SaveResourceState(
                $AuditId,
                $DeploymentId,
                $DeploymentName,
                $ArchetypeInstanceName,
                $ModuleConfigurationName,
                $ResourceStates,
                $ResourceIds,
                $ResourceGroupName,
                $DeploymentTemplate,
                $DeploymentParameters,
                $DeploymentOutputs,
                $TenantId,
                $SubscriptionId,
                $Policies,
                $RBAC);
    }
    catch {
        Write-Host "An error ocurred while running New-DeploymentStateInformation";
        Write-Host $_;
        throw $_;
    }
}

Function New-DeploymentAuditInformation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $BuildId,
        [Parameter(Mandatory=$false)]
        [string]
        $BuildName,
        [Parameter(Mandatory=$false)]
        [string]
        $CommitId,
        [Parameter(Mandatory=$false)]
        [string]
        $CommitMessage,
        [Parameter(Mandatory=$false)]
        [string]
        $CommitUsername, 
        [Parameter(Mandatory=$false)]
        [string]
        $BuildQueuedBy, 
        [Parameter(Mandatory=$false)]
        [string]
        $ReleaseId,
        [Parameter(Mandatory=$false)]
        [string]
        $ReleaseName,
        [Parameter(Mandatory=$false)]
        [string]
        $ReleaseRequestedFor,
        [Parameter(Mandatory=$true)]
        [guid]
        $TenantId,
        [Parameter(Mandatory=$true)]
        [guid]
        $SubscriptionId,
        [Parameter(Mandatory=$true)]
        [object]
        $ArchetypeInstance,
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName
    )

    try {
        return `
            $auditDataService.SaveAuditTrail(
                $BuildId,
                $BuildName,
                $CommitId,
                $CommitMessage,
                $CommitUsername,
                $BuildQueuedBy,
                $ReleaseId,
                $ReleaseName,
                $ReleaseRequestedFor,
                $TenantId,
                $SubscriptionId,
                $ArchetypeInstance,
                $ArchetypeInstanceName);
    }
    catch {
        Write-Host "An error ocurred while running New-DeploymentAuditInformation";
        Write-Host $_;
        throw $_;
    }
}

Function New-NormalizePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]
        $FilePaths
    )

    try {
        $normalizedFilePath = '';

       $FilePaths `
            | ForEach-Object { 
                $normalizedFilePath = `
                    [IO.Path]::Combine($normalizedFilePath, $_);
            };

        return $normalizedFilePath;
    }
    catch {
        Write-Host "An error ocurred while running New-NormalizePath";
        Write-Host $_;
        throw $_;
    }
}

Function Add-OutputsToCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ModuleConfigurationName,
        [Parameter(Mandatory=$true)]
        [hashtable]
        $Outputs
    )

    # Iterate through all the keys in the hashtable
    $Outputs.Keys | ForEach-Object {

        # Retrieve key and value of each parameter entry
        # in the hashtable
        $outputParameterName = $_;

        # Format the Cache Key from the Module Instance Name
        # and output parameter name
        $cacheKey = ("{0}.{1}" -F $ModuleConfigurationName, $outputParameterName);

        # Convert to Json before saving this value
        $cacheValue = `
            $Outputs.$outputParameterName.Value;


        Write-Debug "Adding Output $(ConvertTo-Json $cacheValue -Depth 50) `
              to $cacheKey";

        # Call Add-ItemToCache function to cache them
        # Safe to do .Value because we are caching deployment outputs
        # all deployment outputs contains a Type and Value properties.
        Add-ItemToCache `
            -Key $cacheKey `
            -Value $cacheValue;
    }
}

Function Add-ItemToCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Key,
        [Parameter(Mandatory=$true)]
        [object]
        $Value
    )

    try {
        $cacheDataService.SetByKey(
            $Key,
            $Value); 
    }
    catch {
        Write-Host "An error ocurred while running Add-ItemToCache";
        Write-Host $_;
        throw $_;
    }
}

Function Get-ItemFromCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Key
    )

    try {
        return `
            $cacheDataService.GetByKey($Key); 
    }
    catch {
        Write-Host "An error ocurred while running Get-ItemFromCache";
        Write-Host $_;
        throw $_;
    }
}

Function Merge-Parameters() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $DeploymentParameters,
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ModuleConfiguration,
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [string]
        $Operation
    )
    # Variable to hold the consolidated parameter values
    $deploymentParametersJson = @{};
    $parametersFromDeploymentParameters = @{};
    $overrideParameters = @{};

    if($null -ne $DeploymentParameters) {

        # Convert the string to hashtable before using it
        $deploymentParametersJson = `
            ConvertFrom-Json $DeploymentParameters `
                -AsHashtable `
                -Depth 100;
    }

    # Retrieve the override parameters from the moduleConfiguration.
    # If moduleConfiguration does not have overrideparameters, then
    # assume the override parameters is an empty hashtable.
    if($moduleConfiguration.Keys -eq "Deployment" `
            -and $moduleConfiguration.Deployment.Keys -eq "OverrideParameters") {
            # Retrieve the module instance override parameters
            $overrideParameters = $moduleConfiguration.Deployment.OverrideParameters;
        }

    # Check if the template parameters file has 
    # parameters at the top level and branch accordingly
    if($deploymentParametersJson.Keys -eq "parameters") {
        $parametersFromDeploymentParameters = $deploymentParametersJson.parameters;
    }
    else {
        # Assumes it is a valid deployment parameter file
        $parametersFromDeploymentParameters = $deploymentParametersJson;
    }

    # Account for the following four cases:
    # Case 1: Parameter file present and Override Parameters present
    # Case 2: Parameter file present but No Override Parameters
    # Case 3: No Parameter file but Override Parameters present
    # Case 4: No Parameter file and No Override Parameters
    # If true, we have Case 1 - Parameter file present and Override
    # Parameters present
    if($parametersFromDeploymentParameters.Count -gt 0 `
        -and $overrideParameters.Count -gt 0) {
            
        # Resolve for output references in override parameters
        # Here we are assuming that only override parameters can have 
        # references to outputs
        $overrideParameters = `
            Resolve-OutputReferencesInOverrideParameters `
                -OverrideParameters $overrideParameters `
                -ArchetypeInstanceName $ArchetypeInstanceName `
                -Operation $Operation;

        # Source Parameter Set overrides the Target Parameter Set
        $parametersFromDeploymentParameters = `
            Join-ParameterSets `
                -SourceParameterSet $overrideParameters `
                -TargetParameterSet $parametersFromDeploymentParameters;

    }
    # If true, we have Case 2 - Parameter file present but No Override
    # Parameters
    elseif($parametersFromDeploymentParameters.Count -gt 0) {

        # DeploymentParameters should not have any reference to other 
        # deployment outputs. So return as is.
        return $DeploymentParameters;
    }
    # If true, we have Case 3 - No Parameter file but Override Parameters
    # present
    elseif($overrideParameters.Count -gt 0) {

        # Resolve for output references in override parameters
        # Here we are assuming that only override parameters can have
        # references to outputs
        $overrideParameters = `
            Resolve-OutputReferencesInOverrideParameters `
                -OverrideParameters $overrideParameters `
                -ArchetypeInstanceName $ArchetypeInstanceName `
                -Operation $Operation;

        Write-Debug "Override Parameters are: $(ConvertTo-Json $overrideParameters -Depth 50)";

        # Source Parameter Set overrides the Target Parameter Set
        $parametersFromDeploymentParameters = `
            Join-ParameterSets `
                -SourceParameterSet $overrideParameters `
                -TargetParameterSet $parametersFromDeploymentParameters;

    }
    # Finally, we have Case 4 - No Parameter file and No Override 
    # Parameters
    else {
        # No additional steps needed for this case
        # Return an empty hashtable which was already initialized
        # at the start of this method
    }

    if($deploymentParametersJson.Keys -eq "parameters") {
        # Reassign merged parameters to the template's parameters object.
        $deploymentParametersJson.parameters = $parametersFromDeploymentParameters;
        return `
            ConvertTo-Json $deploymentParametersJson -Depth 100;
    }
    else {
        # Send the deployment parameters as-is (after converting to string)
        return `
            ConvertTo-Json $parametersFromDeploymentParameters -Depth 100;
    }

}

Function Join-ParameterSets() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $SourceParameterSet,
        [Parameter(Mandatory=$false)]
        [hashtable]
        $TargetParameterSet
    )

    # Iterate through the source hashtable and add them to the target hashtable
    # if they are not already present.
    # If they are present, update the target value with the source value
    $SourceParameterSet.Keys | ForEach-Object {
        $sourceParameterName = $_;
        if($TargetParameterSet.Keys -eq $sourceParameterName) {
            $TargetParameterSet.$sourceParameterName = $SourceParameterSet.$sourceParameterName;
        }
        else {
            $TargetParameterSet += @{
                $sourceParameterName = $SourceParameterSet.$sourceParameterName
            }
        }
    }

    return $TargetParameterSet;
}

Function Resolve-OutputReferencesInOverrideParameters() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $OverrideParameters,
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [string]
        $Operation
    )
    # Regex to match for the following format:
    # reference(archetypeInstance.moduleConfiguration.outputName)
    $fullReferenceFunctionMatchRegex = 'reference\((.*)\)';

    # Array that will hold all the parameters with resolved outputs (if any).
    $allOverrideParameters = @{};
    $referenceFunctionParameters = @{};

    if ($Operation -eq "deploy") {
        # For deploy operation, we're checking if we have a reference function, 
        # if it is true, we add the item to referenceFunctionParameters (for 
        # later processing) else we add it to allOverrideParameters.
        # Looping through all Override parameters, since is a hashtable
        # we are getting .Name and .Value
        ($OverrideParameters.GetEnumerator() `
            | ForEach-Object {
                    if((ConvertTo-Json $_.Value -Depth 50 -Compress) `
                            -match $fullReferenceFunctionMatchRegex) {
                                $referenceFunctionParameters += @{ $_.Name = $_.Value };
                    }
                    else {
                        $allOverrideParameters += @{ $_.Name = $_.Value };
                    }
                });
    }
    else {
        # For validate operation, we're checking if we have a referene function or 
        # reference type value in each parameter. If so, we filter them out and 
        # add the rest of the parameters to be overriden during validation.
        ($OverrideParameters.GetEnumerator() `
            | ForEach-Object {
                    if((ConvertTo-Json $_.Value -Depth 50 -Compress) `
                            -notmatch $fullReferenceFunctionMatchRegex `
                            -and $_.Value.Name -ne "reference") {
                        $allOverrideParameters += @{ $_.Name = $_.Value };
                    }
                    else {

                    }
                });
    }

    Write-Debug "Reference functions found: $(ConvertTo-Json $referenceFunctionParameters)"
    # Retrieve hashtable entries that do not have reference functions in value types,
    # or reference types and add them to the resultant hashtable to be returned
        
    
    # Iterate through the parameter names that have reference function in them
    # and resolve them before adding them to the resultant hashtable to be returned
    $referenceFunctionParameters.Keys | ForEach-Object {

        # Initialize a hashtable for the new parameter
        $newParameterValue = @{};

        $parameterName = $_;

        # ParameterValue is a hashtable with two potential types:
        # Type 1: Key: value, value: output with or w/o output reference (i.e reference(archetype-instance.module-instance.parameter))
        # Type 2: Key: reference

        $parameterValue = $OverrideParameters.$parameterName;
        
        Write-Debug "Override parameter with reference function: $parameterValue";

        # For Example: Consider the parameter below:
        # "storageAccountName": @{
        #      "value": "reference(shared-services.storage-account.storageAccountName)"
        # }
        # In this example: 
        # * parameterName is storageAccountName
        # * parameterValue is { "value": "reference(shared-services.diag-storage-account.storageAccountName)" }
        Write-Debug "Let's get the output value";

        # Resolve reference to output by calling Get-OutputReferenceValue and set
        # the resolved value back to the appropriate hashtable as key-value pair entry
        # Note: This function will need to know that the return type will always
        # be a hashtable with the key "result". This is because if the return
        # from the function is an array with one item, the calling function will
        # receive only the item without the array - a known PowerShell Bug.
        $newParameterValue = `
            (Get-OutputReferenceValue `
                -ParameterValue $parameterValue `
                -ArchetypeInstanceName $ArchetypeInstanceName).result;
        Write-Debug "Parameter value resolved from output is: $(ConvertTo-Json $newParameterValue -Depth 50)";

        # Check for falsy to make sure the output was retrieved
        if($null -eq $newParameterValue) {
            throw ("The following output {0} referenced by parameter {1} could not be retrieved" -F $parameterValue, $parameterName);
        }

        # Iterate through the parameters array passed to this method and 
        # add them to the array that will be processed to resolve the references
        $allOverrideParameters += @{ 
            $parameterName = $newParameterValue
        };
    }
    return $allOverrideParameters;
}

Function Get-OutputReferenceValue() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $ParameterValue,
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName
    )

    # Regex to match for the following format:
    # reference(archetypeInstance.moduleConfiguration.outputName)
    $fullReferenceFunctionMatchRegex = '(reference\(.*?\))';
    $outputPathMatchRegex = 'reference\((.*?)\)';

    # This is a string version of the object being passed
    $parameterValueString = "";

    # This is an array that holds the path to retrieve the output
    # from the cache or state store.
    $outputPathArray = $null;

    # First thing, we convert the parameterValue object to string
    # if it is not already a string.
    if($ParameterValue -isnot [string]) {
        $parameterValueString = `
            ConvertTo-Json `
                -InputObject $ParameterValue `
                -Depth 50 `
                -Compress;
    }
    else {
        $parameterValueString = $ParameterValue;
    }

    Write-Debug "Parameter value JSON string is: $parameterValueString";

    # Get all reference functions in the string - parameterValueString
    $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase;
    $referenceFunctionMatches = `
        [regex]::Matches(
            $parameterValueString, 
            $fullReferenceFunctionMatchRegex, 
            $options
        );

    Write-Debug "Reference functions found: $($referenceFunctionMatches.Count)";
    # Iterate through all the reference function matches found
    $referenceFunctionMatches | ForEach-Object {

        # Get the current reference function match
        $referenceFunctionMatch = $_;

        Write-Debug "Reference function to be resolved: $referenceFunctionMatch";

        # Variable to hold our resolved reference function value
        $resolvedOutput = "";

        # If there is a match, its always going to be the index 1 of the match.Groups
        # This regex will match the full string including the reference function itself
        # For Example: Consider the example below:
        # "some-prefix-reference(archetypeInstanceA.moduleConfigurationA.OutputA)-some-suffix"
        # The regex will capture - reference(archetypeInstanceA.moduleConfigurationA.OutputA)
        $fullReferenceFunctionString = $referenceFunctionMatch.Groups[1].Value;

        Write-Debug "Reference function found is: $fullReferenceFunctionString";
        
        # From the full string including reference function captured in the previous step,
        # Extract only the inner string (i.e output path) of the function. Continuing the 
        # previous example, this regex will extract - archetypeInstanceA.moduleConfigurationA.OutputA
        $outputPathStringMatch = `
            [regex]::Match(
                $fullReferenceFunctionString, 
                $outputPathMatchRegex, 
                $options
            );
        $outputPathString = $outputPathStringMatch.Groups[1].Value;

        Write-Debug "Reference function content is: $outputPathString";
        
        # Array does not allow operations like Remove, RemoveAt and so on. We need arraylist to
        # be able to perform these operations. Remove operation will be used to remove the last item
        #  (parameter name) in the array.
        [System.Collections.ArrayList]$outputPathArray = $outputPathString.Split(".");
        Write-Debug "Reference function split: $(ConvertTo-Json $outputPathArray)";

        # Call to retrieve output from cache
        $cacheValue = `
            Get-ItemFromCache `
                -Key $outputPathString;

        # Check if the cache value was retrieval successfully (i.e it returns a value)
        if($cacheValue) 
        {
            Write-Debug "Output found in cache";
            $resolvedOutput = $cacheValue;
        }
        else
        {
            Write-Debug "Output not in cache, let's get it from the storage account";

            # Retrieves output from the state store
            $resolvedOutput = `
                Get-OutputFromStateStore `
                    -Filters $outputPathArray `
                    -ArchetypeInstanceName $ArchetypeInstanceName;
        }

        # Did we resolve the output?
        if($resolvedOutput `
            -and $resolvedOutput -isnot [string]) {
            
            Write-Debug "Converting object into a JSON string";
            # If the resolved output is not already a string, convert it to string before
            # continuing to replace the reference function with the string contents.
            $resolvedOutputString = `
                ConvertTo-Json `
                    -InputObject $resolvedOutput `
                    -Depth 100 `
                    -Compress;

            $parameterValueString = `
                $parameterValueString.Replace(
                    $fullReferenceFunctionString, 
                    $resolvedOutputString
                );
        }
        elseif($resolvedOutput) {

            # If the resolved output is already a string, continue to replace the reference
            # function with the string contents
            $parameterValueString = `
                $parameterValueString.Replace(
                    $fullReferenceFunctionString, 
                    $resolvedOutput
                );
        }
    }


    Write-Debug "Replaced string is: $parameterValueString";
    # Output string needs to be formatted and wrapped before returning
    return `
        Format-ResolvedOutput `
            -OutputValue $parameterValueString;
}

Function Format-ResolvedOutput() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $OutputValue
    )

    # We are wrapping the resolved string into a result property
    # Two reasons to do this:
    # 1. Test-Json will fail for "['a']", however ConvertFrom-Json converts
    # this string correctly to an array. To overcome this, we wrap this into
    # an object so that Test-Json passes.
    # 2. When we have an array of one item, the function will return the item
    # instead of array
    $jsonWrapper = "{'result':$OutputValue}";

    # Test if we can convert the string to an object
    $isJson = `
        Test-Json $jsonWrapper `
            -ErrorAction SilentlyContinue;

    # Truthy for json conversion
    if($isJson) {
        # Convert string to object and return the object
        return `
            ConvertFrom-Json `
                -InputObject $jsonWrapper `
                -AsHashtable `
                -Depth 100;
    }
    else {
        # Still return an object wrapped into a result property
        # because the calling function expects a result property
        return `
            @{ 'result' = $OutputValue };
    }
}

Function Get-OutputFromStateStore() { 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]
        $Filters,
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName
    )
    Write-Debug "All filters: $(ConvertTo-Json $Filters)";

    # Start by retrieving all the outputs for the archetype and/or module instance combination
    if($Filters.Count -ge 3) {
        $archetypeInstanceName = $Filters[0];
        $moduleConfigurationName = $Filters[1];
    }
    elseif($Filters.Count -eq 2) {
        $archetypeInstanceName = $ArchetypeInstanceName;
        $moduleConfigurationName = $Filters[0];
    }
    else {
        # TODO: Check if we need to return null of the filter or at least 2 or more
        return $null;
    }

    Write-Debug "About to retrieve ouputs for: ArchetypeInstanceName: $archetypeInstanceName and Module configuration Name: $moduleConfigurationName";

    # Start by retrieving the outputs for the module instance
    $allOutputs = $moduleStateDataService.GetResourceStateOutputs(
                    $archetypeInstanceName,
                    $moduleConfigurationName
                );

    Write-Debug "Outputs retrieved: $(ConvertTo-Json $allOutputs)"

    # Retrieve only the output parameter name which is always the last index in the array
    $outputParameterName = `
        $Filters[$outputPathArray.Count -1];

    if ($null -ne $allOutputs) {
        Write-Debug "Outputs found, proceed to cache the values";

        $allOutputs.Keys | ForEach-Object {
            $parameterName = $_;
            # Doing .Value because is a deployment output parameter
            $parameterValue = $allOutputs.$parameterName.Value;
            Write-Debug "Cache Key: $($moduleConfigurationName.$parameterName)";
            Write-Debug "Cache Value is: $parameterValue";
            # Cache the retrieved value by calling set method on cache data service with key and value
            $cacheDataService.SetByKey(
                "$moduleConfigurationName.$parameterName",
                $parameterValue);
        }

        # Find the specific output 
        if($allOutputs.Keys -eq $outputParameterName) {
            return $allOutputs.$outputParameterName.Value;
        }
        else {
            return $null;
        }
    }
    else {
        Write-Debug "Outputs not found";
        return $null;
    }
}

New-Deployment `
    -ArchetypeDefinitionPath $ArchetypeDefinitionPath `
    -ArchetypeInstanceName $ArchetypeInstanceName `
    -ModuleConfigurationName $ModuleConfigurationName `
    -WorkingDirectory $WorkingDirectory `
    -Validate:$($Validate.IsPresent);
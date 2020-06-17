[CmdletBinding(DefaultParametersetName='None')]
    param (
    [Parameter(Mandatory=$false)]
    [string]
    $ArchetypeInstanceName,
    [Parameter(Mandatory=$true)]
    [string]
    $DefinitionPath,
    [Parameter(Mandatory=$false)]
    [string]
    $ModuleConfigurationName,
    [Parameter(Mandatory=$false)]
    [string]
    $WorkingDirectory,
    [Parameter(Mandatory=$false)]
    [string]
    $ToolkitConfigurationFilePath = '/Config/toolkit.config.json',
    [Parameter(Mandatory=$false)]
    [switch]
    $Validate,
    [Parameter(Mandatory=$false)]
    [switch]
    $TearDownValidationResourceGroup,
    [Parameter(Mandatory=$false)]
    [switch]
    $TearDownEnvironment,
    [Parameter(ParameterSetName='Transcript',Mandatory=$false)]
    [switch]
    $GenerateTranscript,
    [Parameter(ParameterSetName='Transcript',Mandatory=$true)]
    [string]
    $TranscriptPath
    )

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent;
$bootstrapModulePath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath @('Bootstrap', 'Initialize.ps1');
$scriptBlock = ". $bootstrapModulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$factoryModulePath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath @('Factory', 'Factory.psd1');
Import-Module $bootstrapModulePath -Force;
Import-Module $factoryModulePath -Force;
Import-Module "$($rootPath)/../Common/Helper.psd1" -Force;

$global:deploymentService = $null;
$global:cacheDataService = $null;
$global:auditDataService = $null;
$global:moduleStateDataService = $null;
$global:configurationBuilder = $null;
$global:customScriptExecution = $null
$global:factory = $null;
$defaultLocation = "West US";
$defaultModuleConfigurationsFolderName = "Modules";
$defaultTemplateFileName = "deploy.json";
$defaultParametersFileName = "parameters.json";

# Get/Set the BLOB Storage & Management URL based on Azure Environment
$discUrlResponse = Get-AzureApiUrl -AzureEnvironment $ENV:AZURE_ENVIRONMENT_NAME -AzureDiscoveryUrl $ENV:AZURE_DISCOVERY_URL
$ENV:AZURE_STORAGE_BLOB_URL = $discUrlResponse.suffixes.storage
$AzureManagementUrl = $discUrlResponse.authentication.audiences[1]
Write-Debug "AZURE_STORAGE_BLOB_URL: $ENV:AZURE_STORAGE_BLOB_URL"
Write-Debug "AzureManagementUrl: $AzureManagementUrl"
$ENV:VDC_SUBSCRIPTIONS = (Get-Content .\Environments\_Common\subscriptions.json -Raw)
$ENV:VDC_TOOLKIT_SUBSCRIPTION = (Get-Content .\Config\toolkit.subscription.json -Raw)
Write-Debug "AZURE_STORAGE_BLOB_URL: $ENV:AZURE_STORAGE_BLOB_URL"
Write-Debug "AzureManagementUrl: $AzureManagementUrl"

Function Start-Deployment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [string]
        $DefinitionPath,
        [Parameter(Mandatory=$false)]
        [string]
        $ToolkitConfigurationFilePath,
        [Parameter(Mandatory=$false)]
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

        $initializedValues = `
            Start-Init `
                -WorkingDirectory $WorkingDirectory `
                -DefinitionPath $DefinitionPath `
                -ToolkitConfigurationFilePath $ToolkitConfigurationFilePath `
                -ArchetypeInstanceName $ArchetypeInstanceName `
                -Validate:$($Validate.IsPresent);

        $defaultWorkingDirectory = $initializedValues.WorkingDirectory
        $archetypeInstanceJson = $initializedValues.ArchetypeInstanceJson
        $archetypeInstanceName = $initializedValues.ArchetypeInstanceName
        $location = $initializedValues.Location

        $allModules = Get-AllModules `
            -ModuleConfigurationName $ModuleConfigurationName `
            -ArchetypeInstanceJson $archetypeInstanceJson

        foreach($ModuleConfigurationName in $allModules) {
            Write-Host "Deploying Module: $ModuleConfigurationName" -ForegroundColor Yellow
            $moduleConfiguration = `
                Get-ModuleConfiguration `
                    -ArchetypeInstanceJson $archetypeInstanceJson `
                    -ModuleConfigurationName $moduleConfigurationName `
                    -ArchetypeInstanceName $ArchetypeInstanceName `
                    -Operation @{ "False" = "deploy"; "True" = "validate"; }[$Validate.ToString()];;

            if ($null -eq $moduleConfiguration) {
                throw "Module configuration not found for module name: $moduleConfigurationName";
            }
            elseif ($moduleConfiguration.Enabled -eq $false) {
                Write-Host "Module is disabled, enable it by setting -> """Enabled""": true on module: $moduleConfigurationName" -ForegroundColor Red
            }
            else {

                Write-Debug "Module instance is: $(ConvertTo-Json $moduleConfiguration)";

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
            -SubscriptionName $archetypeInstanceJson.Parameters.Subscription `
            -ModuleConfiguration $moduleConfiguration `
            -Mode @{ "False" = "deploy"; "True" = "validate"; }[$Validate.ToString()];

        if ($null -eq $subscriptionInformation) {
            throw "Subscription: $($archetypeInstanceJson.Parameters.Subscription) not found";
        }
                
                # Let's get the current subscription context
                $sub = Get-AzContext | Select-Object Subscription

                # Do not change the subscription context if the operation is validate.
                # This is because the script will expect the validation resource
                # group to be present in all the subscriptions we are deploying.
                [Guid]$subscriptionCheck = [Guid]::Empty;
                [Guid]$tenantIdCheck = [Guid]::Empty;
                if($null -ne $subscriptionInformation -and `
                    [Guid]::TryParse($subscriptionInformation.SubscriptionId, [ref]$subscriptionCheck) -and `
                    [Guid]::TryParse($subscriptionInformation.TenantId, [ref]$tenantIdCheck) -and `
                    $subscriptionCheck -ne [Guid]::Empty -and `
                    $tenantIdCheck -ne [Guid]::Empty -and
                    $subscriptionCheck -ne $sub.Subscription.Id) {

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
                            -TenantId @("",$subscriptionInformation.TenantId)[$null -ne $subscriptionInformation] `
                            -SubscriptionId @("", $subscriptionInformation.SubscriptionId)[$null -ne $subscriptionInformation] `
                            -ArchetypeInstance $archetypeInstanceJson `
                            -ArchetypeInstanceName $ArchetypeInstanceName `
                            -Validate:$($Validate.IsPresent);
                    Write-Debug "Audit trail created, Id: $auditId";

                    Add-ItemToCache `
                        -Key $auditCacheKey `
                        -Value $auditId `
                        -Validate:$($Validate.IsPresent);
                    Write-Debug "Audit Id succesfully cached.";
                }

                # Runs a custom script only if Script property is present and
                # we are not in Validation mode
                if($null -ne $ModuleConfiguration.Script `
                    -and `
                   $null -ne $ModuleConfiguration.Script.Command) {
         
                    # Orchestrate the deployment of Custom Scripts
                    $result = `
                        New-CustomScripts `
                            -ModuleConfiguration $moduleConfiguration `
                            -ArchetypeInstanceJson $archetypeInstanceJson `
                            -Validate:$($Validate.IsPresent);
         
                    # Retrieve the results from the script deployment
                    $resourceState = $result[0];
         
                    # Did the ArchetypeInstanceJson change?
                    if($null -ne $result[1]) {
                        # Set the ArchetypeInstanceJson only if it is
                        # modified by the custom script deployment
                        $archetypeInstanceJson = $result[1];
         
                        # Re-cache the ArchetypeInstanceJson
                        Add-ItemToCache `
                            -Key $ArchetypeInstanceName `
                            -Value $archetypeInstanceJson `
                            -Validate:$($Validate.IsPresent);
                    }     
                }
                else {

                    # Let's get the module's template information first,
                    # this template will dictate if is a resource group or
                    # subscription deployment based on the template's schema
                    $moduleConfigurationDeploymentInformation = `
                        Get-DeploymentTemplateFileContents `
                            -DeploymentConfiguration $moduleConfiguration.Deployment `
                            -ModuleConfigurationsPath $archetypeInstanceJson.Orchestration.ModuleConfigurationsPath `
                            -WorkingDirectory $defaultWorkingDirectory;

                    $moduleConfigurationDeploymentParameters = $null;

                    $isSubscriptionDeployment = $false;

                    if($null -ne $moduleConfigurationDeploymentInformation) {

                        $moduleConfigurationDeploymentTemplate = `
                            $moduleConfigurationDeploymentInformation.Template;

                        # Let's get the information if is a subscription
                        # level deployment or resource group level deployment
                        $isSubscriptionDeployment = `
                            $moduleConfigurationDeploymentInformation.IsSubscriptionDeployment;

                        Write-Debug "Deployment template contents is: $moduleConfigurationDeploymentTemplate";

                        # If a module deployment template exists,
                        # let's get the deployment parameters.
                        $moduleConfigurationDeploymentParameters = `
                            Get-DeploymentParametersFileContents `
                                -DeploymentConfiguration $moduleConfiguration.Deployment `
                                -ModuleConfigurationsPath $archetypeInstanceJson.Orchestration.ModuleConfigurationsPath `
                                -WorkingDirectory $defaultWorkingDirectory;
                    }
                    else {
                        throw "No Resource Manager template found under Deployment.";
                    }

                    Write-Debug "Is a subscription deployment: $isSubscriptionDeployment";

                    $moduleConfigurationResourceGroupName = "";

                    # If we are not in a subscription deployment
                    # proceed to create a resource group
                    if ($null -ne $subscriptionInformation -and `
                        -not $isSubscriptionDeployment) {
                        $moduleConfigurationResourceGroupName = `
                            Get-ResourceGroupName `
                                -ArchetypeInstanceName $ArchetypeInstanceName `
                                -ModuleConfiguration $moduleConfiguration;
                            Write-Debug "Resource Group is: $moduleConfigurationResourceGroupName";

                        New-ResourceGroup `
                            -ResourceGroupName $moduleConfigurationResourceGroupName `
                            -ResourceGroupLocation $location `
                            -Validate:$($Validate.IsPresent);
                        Write-Debug "Resource Group successfully created";
                    }

                    # Now continue deploying Policies, RBAC and finally
                    # the module template
                    $moduleConfigurationPolicyDeploymentTemplate = `
                        Get-PolicyDeploymentTemplateFileContents `
                            -DeploymentConfiguration $moduleConfiguration.Policies `
                            -ModuleConfigurationsPath $archetypeInstanceJson.Orchestration.ModuleConfigurationsPath `
                            -WorkingDirectory $defaultWorkingDirectory;
                    Write-Debug "Policy Deployment template contents is: $moduleConfigurationPolicyDeploymentTemplate";

                    $moduleConfigurationPolicyDeploymentParameters = `
                        Get-PolicyDeploymentParametersFileContents `
                            -DeploymentConfiguration $moduleConfiguration.Policies `
                            -ModuleConfigurationsPath $archetypeInstanceJson.Orchestration.ModuleConfigurationsPath `
                            -WorkingDirectory $defaultWorkingDirectory;
                    Write-Debug "Policy Deployment parameters contents is: $moduleConfigurationPolicyDeploymentParameters";

                    $policyResourceState = @{};

                    if ($null -ne $moduleConfigurationPolicyDeploymentTemplate) {
                            Write-Debug "About to trigger a deployment";
                            $policyResourceState = `
                            New-AzureResourceManagerDeployment `
                                -TenantId $subscriptionInformation.TenantId `
                                -SubscriptionId $subscriptionInformation.SubscriptionId `
                                -ResourceGroupName $moduleConfigurationResourceGroupName `
                                -DeploymentTemplate $moduleConfigurationPolicyDeploymentTemplate `
                                -DeploymentParameters $moduleConfigurationPolicyDeploymentParameters `
                                -ModuleConfiguration $moduleConfiguration.Policies `
                                -ArchetypeInstanceName $ArchetypeInstanceName `
                                -Location $location `
                                -Validate:$($Validate.IsPresent) `
                                -AzureManagementUrl $AzureManagementUrl;
                            Write-Debug "Deployment complete, Resource state is: $(ConvertTo-Json -Compress $policyResourceState)";
                    }
                    else {
                        Write-Debug "No Policy deployment";
                    }

                    $moduleConfigurationRBACDeploymentTemplate = `
                        Get-RbacDeploymentTemplateFileContents `
                            -DeploymentConfiguration $moduleConfiguration.RBAC `
                            -ModuleConfigurationsPath $archetypeInstanceJson.Orchestration.ModuleConfigurationsPath `
                            -WorkingDirectory $defaultWorkingDirectory;
                    Write-Debug "RBAC Deployment template contents is: $moduleConfigurationRBACDeploymentTemplate";

                    # If we are not in a subscription deployment
                    # proceed to create a resource group
                    if ($null -ne $subscriptionInformation -and `
                        -not $isSubscriptionDeployment) {

                        if($Validate.IsPresent -eq $false) {
                            # Retrieve the deployment resource group name
                            $moduleConfigurationResourceGroupName = `
                                Get-ResourceGroupName `
                                        -ArchetypeInstanceName $ArchetypeInstanceName `
                                        -ModuleConfiguration $moduleConfiguration;
                        }
                        elseif($Validate.IsPresent -eq $true) {

                            $moduleConfigurationResourceGroupName = `
                                $initializedValues.ValidationResourceGroupInformation.Name;

                            # if location is provided in the validation resource group property of the configuration object in
                            # the toolkit config json, then use it.
                            if(![string]::IsNullOrEmpty($initializedValues.ValidationResourceGroupInformation.Location)) {
                                $location = `
                                    $initializedValues.ValidationResourceGroupInformation.Location;
                            }
                        }
                        Write-Debug "Resource Group is: $moduleConfigurationResourceGroupName";

                        New-ResourceGroup `
                            -ResourceGroupName $moduleConfigurationResourceGroupName `
                            -ResourceGroupLocation $location `
                            -Tags $moduleConfigurationResourceGroupInformation.Tags `
                            -Validate:$($Validate.IsPresent);

                        Write-Debug "Resource Group successfully created";
                    }

                    if ($null -ne $moduleConfigurationRBACDeploymentTemplate) {
                        Write-Debug "About to trigger a deployment";
                        $rbacResourceState = `
                            New-AzureResourceManagerDeployment `
                                -TenantId $subscriptionInformation.TenantId `
                                -SubscriptionId $subscriptionInformation.SubscriptionId `
                                -ResourceGroupName $moduleConfigurationResourceGroupName `
                                -DeploymentTemplate $moduleConfigurationRBACDeploymentTemplate `
                                -DeploymentParameters $moduleConfigurationRBACDeploymentParameters `
                                -ModuleConfiguration $moduleConfiguration.RBAC `
                                -ArchetypeInstanceName $ArchetypeInstanceName `
                                -Location $location `
                                -Validate:$($Validate.IsPresent) `
                                -AzureManagementUrl $AzureManagementUrl;
                        Write-Debug "Deployment complete, Resource state is: $(ConvertTo-Json -Compress $rbacResourceState)";
                    }
                    else {
                        Write-Debug "No RBAC deployment";
                    }

                    # This deployment runs last because it could be
                    # a Subscription or Resource Group level deployment
                    if ($null -ne $moduleConfigurationDeploymentTemplate) {
                        Write-Debug "About to trigger a deployment";
                        $resourceState = `
                            New-AzureResourceManagerDeployment `
                                -TenantId $subscriptionInformation.TenantId `
                                -SubscriptionId $subscriptionInformation.SubscriptionId `
                                -ResourceGroupName $moduleConfigurationResourceGroupName `
                                -DeploymentTemplate $moduleConfigurationDeploymentTemplate `
                                -DeploymentParameters $moduleConfigurationDeploymentParameters `
                                -ModuleConfiguration $moduleConfiguration.Deployment `
                                -ArchetypeInstanceName $ArchetypeInstanceName `
                                -Location $location `
                                -Validate:$($Validate.IsPresent) `
                                -AzureManagementUrl $AzureManagementUrl;
                        Write-Debug "Deployment complete, Resource state is: $(ConvertTo-Json -Compress $resourceState)";
                    }
                }

                # If there are deployment outputs, cache the values
                if ($null -ne $resourceState.DeploymentOutputs) {

                    Add-OutputsToCache `
                        -ModuleConfigurationName $moduleConfigurationName `
                        -Outputs $resourceState.DeploymentOutputs `
                        -Validate:$($Validate.IsPresent);
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
                        -TenantId @("", $subscriptionInformation.TenantId)[$null -ne $subscriptionInformation] `
                        -SubscriptionId @("", $subscriptionInformation.SubscriptionId)[$null -ne $subscriptionInformation] `
                        -Policies $policyResourceState `
                        -RBAC $rbacResourceState `
                        -Validate:$($Validate.IsPresent);
                Write-Debug "Module state created, Id: $($moduleStateId)";

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
                        -TenantId @("", $subscriptionInformation.TenantId)[$null -ne $subscriptionInformation] `
                        -SubscriptionId @("", $subscriptionInformation.SubscriptionId)[$null -ne $subscriptionInformation] `
                        -Policies $policyResourceState `
                        -RBAC $rbacResourceState `
                        -Validate:$($Validate.IsPresent);
                Write-Debug "Module state created, Id: $($moduleStateId)";
            }

            # Finally, destroy the validation resource group only if the following conditions are satisfied:
            # 1. Deployment is run in Validate mode
            # 2. TearDownValidationResourceGroup flag is present
            if($Validate.IsPresent -eq $true -and `
                    $TearDownValidationResourceGroup.IsPresent -eq $true) {

                Write-Debug "Validation Resource Group is being destroyed ..."

                # Destroy the validation Resource Group
                Remove-ValidationResourceGroup `
                        -ArchetypeInstanceName $ArchetypeInstanceName `
                        -ValidationResourceGroupInformation $initializedValues.ValidationResourceGroupInformation;

                Write-Host "Validation Resource Group is destroyed."
            }

        }
    }
    catch {
        Write-Host "An error ocurred while running New-Deployment";
        $errorMessage = `
            $(Get-Exception -ErrorObject $_);
        Write-Error $errorMessage;
    }
}

Function Start-TearDownEnvironment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [string]
        $DefinitionPath,
        [Parameter(Mandatory=$false)]
        [string]
        $ToolkitConfigurationFilePath,
        [Parameter(Mandatory=$false)]
        [string]
        $ModuleConfigurationName,
        [Parameter(Mandatory=$false)]
        [string]
        $WorkingDirectory
    )
        # WorkingDirectory is required to construct
        # modules folder, deployment and parameters file paths
        # when no value is specified. If no value is specified,
        # we assume that the folders and files will be
        # relative to the working directory (root of the repository).
        # WorkingDirectory is required when running the script
        # from a local computer.
    try {
        $initializedValues = `
            Start-Init `
                -WorkingDirectory $WorkingDirectory `
                -DefinitionPath $DefinitionPath `
                -ToolkitConfigurationFilePath $ToolkitConfigurationFilePath `
                -ArchetypeInstanceName $ArchetypeInstanceName `
                -Validate;

        $archetypeInstanceJson = $initializedValues.ArchetypeInstanceJson
        $archetypeInstanceName = $initializedValues.ArchetypeInstanceName
        Write-Debug "Values retrieved from Init: $(ConvertTo-Json $initializedValues)"
        $allModules = Get-AllModules `
            -ModuleConfigurationName $ModuleConfigurationName `
            -ArchetypeInstanceJson $archetypeInstanceJson
        Write-Debug "All modules: $(ConvertTo-Json $allModules)"

        [array]::Reverse($allModules)

        Write-Debug "Reversed module list: $(ConvertTo-Json $allModules)"

        # TODO: Use a C# data structure (List<>) instead of a Powershell hashtable
        $allResourceGroupsToDelete = @{}
        $allResourceGroupsDeleted = $false
        $loop = 0
        while (!$allResourceGroupsDeleted) {
            $loop++
            foreach($ModuleConfigurationName in $allModules) {

                Write-Host "Deleting Module: $ModuleConfigurationName in loop number: $loop" -ForegroundColor Yellow
                $moduleConfiguration = `
                    Get-ModuleConfiguration `
                        -ArchetypeInstanceJson $archetypeInstanceJson `
                        -ModuleConfigurationName $moduleConfigurationName `
                        -ArchetypeInstanceName $ArchetypeInstanceName `
                        -Operation "Validate"

                if ($null -eq $moduleConfiguration) {
                    throw "Module configuration not found for module name: $moduleConfigurationName";
                }
                elseif ($moduleConfiguration.Enabled -eq $false) {
                    Write-Host "Module is disabled, enable it by setting -> """Enabled""": true on module: $moduleConfigurationName" -ForegroundColor Red
                }
                else {

                    Write-Debug "Module instance is: $(ConvertTo-Json $moduleConfiguration)";

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
                            -SubscriptionName $archetypeInstanceJson.Parameters.Subscription `
                            -ModuleConfiguration $moduleConfiguration  `
                            -Mode @{ "False" = "deploy"; "True" = "validate"; }[$Validate.ToString()];

                    if ($null -eq $subscriptionInformation) {
                        throw "Subscription: $($archetypeInstanceJson.Parameters.Subscription) not found";
                    }
                    elseif ($subscriptionInformation.SubscriptionId -ne `
                            $archetypeInstanceJson.Parameters.SubscriptionId) {
                        Write-Host "Module: $ModuleConfigurationName belongs to a different subscription: $($moduleConfiguration.Subscription), skipping the deletion process" -ForegroundColor Green
                    }
                    else {
                        # Let's get the current subscription context
                        $sub = Get-AzContext | Select-Object Subscription

                        # Do not change the subscription context if the operation is validate.
                        # This is because the script will expect the validation resource
                        # group to be present in all the subscriptions we are deploying.
                        [Guid]$subscriptionCheck = [Guid]::Empty;
                        [Guid]$tenantIdCheck = [Guid]::Empty;
                        if($null -ne $subscriptionInformation -and `
                            [Guid]::TryParse($subscriptionInformation.SubscriptionId, [ref]$subscriptionCheck) -and `
                            [Guid]::TryParse($subscriptionInformation.TenantId, [ref]$tenantIdCheck) -and `
                            $subscriptionCheck -ne [Guid]::Empty -and `
                            $tenantIdCheck -ne [Guid]::Empty -and
                            $subscriptionCheck -ne $sub.Subscription.Id) {

                            Write-Debug "Setting subscription context";
                            Write-Debug "Deployment service object is: $deploymentService"

                            Set-SubscriptionContext `
                                -SubscriptionId $subscriptionInformation.SubscriptionId `
                                -TenantId $subscriptionInformation.TenantId;
                        }

                        if($null -eq $ModuleConfiguration.Script `
                            -and `
                           $null -eq $ModuleConfiguration.Script.Command) {

                            $moduleConfigurationResourceGroupName = `
                                Get-ResourceGroupName `
                                    -ArchetypeInstanceName $archetypeInstanceName `
                                    -ModuleConfiguration $moduleConfiguration;
                            Write-Debug "Resource Group is: $moduleConfigurationResourceGroupName";

                            $resourceGroupFound = $deploymentService.GetResourceGroup(
                                $subscriptionInformation.SubscriptionId,
                                $moduleConfigurationResourceGroupName
                            )

                            # Let's check if the resource group exists and the resource group name
                            # hasn't been added to allResourceGroupsToDelete hashtable or if the resource group
                            # is not in deleting status (maybe it failed the deletion the first time)
                            if ($null -ne $resourceGroupFound -and `
                                ( $null -eq $allResourceGroupsToDelete.$moduleConfigurationResourceGroupName -or `
                                  $resourceGroupFound | Where-Object "ProvisioningState" -ne "Deleting") ) {

                                # Add to temporal hashtable if is not already added
                                # Adding the item with a Value = false, which means that the resource group
                                # hasn't been deleted yet, one the resource group gets deleted, this value
                                # will switch to true
                                if ($null -eq $allResourceGroupsToDelete.$moduleConfigurationResourceGroupName) {
                                    $allResourceGroupsToDelete += @{
                                        $moduleConfigurationResourceGroupName = $false
                                    }
                                }

                                # Start deleting the resource group locks and resource group

                                Write-Debug "Deleting all resource locks"
                                $deploymentService.RemoveResourceGroupLock(
                                    $subscriptionInformation.SubscriptionId,
                                    $moduleConfigurationResourceGroupName
                                )

                                Write-Debug "Deleting resource group: $moduleConfigurationResourceGroupName"

                                $deploymentService.RemoveResourceGroup(
                                    $subscriptionInformation.SubscriptionId,
                                    $moduleConfigurationResourceGroupName
                                )
                            }
                            elseif ($null -eq $resourceGroupFound -and `
                                    $allResourceGroupsToDelete.$moduleConfigurationResourceGroupName -eq $false) {
                                # Update the flag to true
                                Write-Debug "Resource group successfully deleted"
                                $allResourceGroupsToDelete.$moduleConfigurationResourceGroupName = $true
                            }
                            elseif (($allResourceGroupsToDelete.GetEnumerator() | Where-Object { $_.Value -eq $false }).Count -eq 0) {
                                Write-Debug "No more resource groups to delete, stopping the loop"
                                # Let's stop the loop
                                $allResourceGroupsDeleted = $true
                            }
                            else {
                                # Continue
                            }
                        }
                    }
                }
            }

            # Finished first loop, let's wait for a minute
            # to give time for the resource group to get deleted
            if ($allResourceGroupsDeleted -eq $false) {
                Write-Debug "Starting sleep"
                Start-Sleep -Seconds 60
            }
        }
    }
    catch {
        Write-Host "An error ocurred while running TearDownEnvironment";
        Write-Host $_;
        throw $_;
    }
}

Function Start-Init {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [string]
        $DefinitionPath,
        [Parameter(Mandatory=$false)]
        [string]
        $ToolkitConfigurationFilePath,
        [Parameter(Mandatory=$false)]
        [string]
        $WorkingDirectory,
        [Parameter(Mandatory=$false)]
        [switch]
        $Validate
    )
    try {
        $defaultWorkingDirectory = `
            Get-WorkingDirectory `
                -WorkingDirectory $WorkingDirectory;

        Write-Debug "Working directory is: $defaultWorkingDirectory";

        $bootstrappedValues = `
            Invoke-Bootstrap `
                -WorkingDirectory $defaultWorkingDirectory `
                -ToolkitConfigurationFilePath $ToolkitConfigurationFilePath `
                -Mode @{ "False" = "deploy"; "True" = "validate"; }[$Validate.ToString()];

        $global:factory = $bootstrappedValues.Factory

        $global:deploymentService = `
            $factory.GetInstance('IDeploymentService');

        $global:cacheDataService = `
            $factory.GetInstance('ICacheDataService');

        $global:auditDataService = `
            $factory.GetInstance('IDeploymentAuditDataService');

        $global:moduleStateDataService = `
            $factory.GetInstance('IModuleStateDataService');

        $global:customScriptExecution = `
            $factory.GetInstance('CustomScriptExecution');
        
        # Contruct the archetype instance object only if it is not already
        # cached
        $archetypeInstanceJson = `
            New-ConfigurationInstance `
                -FilePath $DefinitionPath `
                -WorkingDirectory $defaultWorkingDirectory `
                -CacheKey $ArchetypeInstanceName;

        $location = ''

        # Check for invariant
        if ($null -eq $archetypeInstanceJson.Parameters.Location) {
            throw "Location value is not present in the archetype parameters file"
        }
        else {
            $location = $archetypeInstanceJson.Parameters.Location
        }

        Write-Debug ($archetypeInstanceJson.Orchestration.ModuleConfigurations.Deployment.OverrideParameters[10].storageBlobUrl | Format-Table | Out-String)
        Write-Debug ($archetypeInstanceJson.Parameters | Format-Table | Out-String)

        # Retrieve the Archetype instance name if not already passed
        # to this function
        $archetypeInstanceName = `
            Get-ArchetypeInstanceName `
                -ArchetypeInstance $archetypeInstanceJson `
                -ArchetypeInstanceName $ArchetypeInstanceName;

        return @{
            WorkingDirectory = $defaultWorkingDirectory
            ArchetypeInstanceJson = $archetypeInstanceJson
            ArchetypeInstanceName = $archetypeInstanceName
            ValidationResourceGroupInformation = $bootstrappedValues.ValidationResourceGroupInformation
            Location = $location
        }
    }
    catch {
        Write-Host "An error ocurred while running Start-Init";
        Write-Host $_;
        throw $_;
    }
}

Function Get-AllModules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]
        $ModuleConfigurationName,
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ArchetypeInstanceJson
    )
    try {
        $allModules = @()
        if ([string]::IsNullOrEmpty($ModuleConfigurationName)) {

            $topologicalSortRootPath = `
                Join-Path $rootPath -ChildPath 'TopologicalSort';
            
            # Adding Out-Null to prevent outputs from the Invoke-Command from being added to            
            Invoke-Command -ScriptBlock { dotnet build $topologicalSortRootPath --configuration Release --output ./ } | Out-Null
            
            
            $topologicalSortAssemblyPath = Join-Path $topologicalSortRootPath "TopologicalSort.dll"

            Add-Type -Path $topologicalSortAssemblyPath

            $graph = [VDC.Core.DirectedGraph]::new()
            $orchestrationJson = `
                ConvertTo-Json $ArchetypeInstanceJson.Orchestration.ModuleConfigurations
            $graph.Generate($orchestrationJson)
            $graph.DFS()
            $graph.TopologicalSort | ForEach-Object { $allModules += $_.Name }

            if ($allModules.Count -eq 0) {
                Write-Host "No modules found or all are disabled, please verify your ModuleConfigurations array" -ForegroundColor Red
            }
        }
        else {
            $allModules += $ModuleConfigurationName
        }

        return $allModules
    }
    catch {
        Write-Host "An error ocurred while running Get-AllModules";
        Write-Host $_;
        throw $_;
    }
}

Function Get-WorkingDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]
        $WorkingDirectory
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

            $defaultWorkingDirectory = `
                "$systemDefaultWorkingDirectory\$releasePrimaryArtifactSourceAlias";
        }
        # This is true when the running the script locally
        else {
            Write-Debug "Local deployment, attempting to resolve root path";
            # If no explicity working directory is passed and the script
            # is run locally, then use the current path
            $defaultWorkingDirectory = (Resolve-Path ".\").Path;
        }

        return $defaultWorkingDirectory;
    }
    catch {
        Write-Host "An error ocurred while running Get-WorkingDirectory";
        Write-Host $_;
        throw $_;
    }
}

Function New-CustomScripts {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ModuleConfiguration,
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ArchetypeInstanceJson,
        [Parameter(Mandatory=$false)]
        [switch]
        $Validate
    )

    try {
        $result = @($null, $null);
 
        if(-not $Validate.IsPresent) {
            # Run and retrieve the script output, if any.
            $scriptOutput = `
                Start-CustomScript `
                    -ModuleConfiguration $ModuleConfiguration;
         
            # Update the archetype instance json
            if($null -ne $scriptOutput `
                -and $null -ne $ModuleConfiguration.Script `
                -and $null -ne $ModuleConfiguration.Script.UpdatePath) {
         
                    # Update the ArchetypeInstanceJson if UpdatePath is
                    # Present
                    $ArchetypeInstanceJson = `
                        Update-ArchetypeInstanceConfiguration `
                            -ArchetypeInstance $ArchetypeInstanceJson `
                            -PropertyPath $ModuleConfiguration.Script.UpdatePath `
                            -Output $scriptOutput;
         
                    # Update the result array with the updated ArchetypeInstanceJson
                    $result[1] = $ArchetypeInstanceJson;
            }
           
            # Returning the minimal resource state object
            $resourceState += @{
                DeploymentId = [Guid]::NewGuid()
                DeploymentName = [Guid]::NewGuid().ToString()
                ResourceStates = @()
                ResourceIds = @()
                ResourceGroupName = $null
                DeploymentTemplate = $null
                DeploymentParameters = $null
                Type = "CustomScript"
               
            }         

            $deploymentOutputs = @{};
           
            # Proceed only if there is output from script

            $tmpOutput = $null;
            $type = '';

            # We have to do a .ToString() to force Powershell to set the original returned
            # value otherwise Powershell detects that $scriptOutput is an object and
            # will preserve it which results in having a $deploymentOutputs.Output
            # equals to an object instead of the desired returned string
            if ($null -ne $scriptOutput -and `
                $scriptOutput.GetType().ToString().ToLower() -like "*string") {
                $tmpOutput = $scriptOutput.ToString();
                $type = "String";
            }
            elseif($null -ne $scriptOutput){
                # TODO: Analyze other types.
                $type = "Object";
                $tmpOutput = $scriptOutput;
            }

            if($null -ne $tmpOutput) {
                $deploymentOutputs = `
                    @{
                        "output" = @{
                            "Type" = $type
                            "Value" = $tmpOutput;
                        }
                    }
            }

            $resourceState += @{       
                "DeploymentOutputs" = $deploymentOutputs
            };
            # Set the resultant resourceState as the first item of
            # the result array to be returned.
            $result[0] = $resourceState;
        }
        # Return the result array
        return $result;
    }
    catch {
        Write-Host "An error ocurred while running Start-CustomScript";
        Write-Host $_;
        throw $_;
    }
}
     
Function Start-CustomScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ModuleConfiguration
    )
 
    try {
        # Execute the script by calling Execute method
        $scriptOutput = $customScriptExecution.Execute(
           $ModuleConfiguration.Script.Command,
            $ModuleConfiguration.Script.Arguments
            );
 
        # Return the result of script execution
        return $scriptOutput;
    }
    catch {
        Write-Host "An error ocurred while running Start-CustomScript";
        Write-Host $_;
        throw $_;
    }
}
 
Function Update-ArchetypeInstanceConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable] $ArchetypeInstanceJson,
        [Parameter(Mandatory=$true)]
        [string] $PropertyPath,
        [Parameter(Mandatory=$true)]
        [object] $Output
    )

    try {
        # Check if the string returned is a JSON string
        $isJson = `
        Test-Json $Output `
            -ErrorAction SilentlyContinue;
     
        # If we can convert to object, then return converted object
        # else return string
        if($isJson) {
            $Output = `
                ConvertFrom-Json `
                    -InputObject $Output `
                    -Depth 50;
        }
     
        # Get PropertyPath and split it to get individual properties
        $propertyPathArray = $PropertyPath.Split('.');
     
        # Initialize the PropertyObject to the ArchetypeInstanceJson
        $propertyObject = $ArchetypeInstanceJson;
     
        # Drill down to the property through the path provided in the
        # UpdatePath. We only iterate to the n-1 node, i.e stop one
        # property path short.
        for($i = 0; $i -lt $propertyPathArray.Count - 1; $i++) {
            $propertyName = $propertyPathArray[$i];
            if($propertyObject.ContainsKey($propertyName)) {
                $propertyObject = $propertyObject.$propertyName;
            }
            else {
                Throw "Property Path $PropertyPath is an invalid path";
            }
        }
     
        # Get the leaf property name
        $leafPropertyName = $($propertyPathArray[$propertyPathArray.Count-1]);
     
        # Set the value represented by the property path to the output value passed
        $propertyObject.$leafPropertyName = $Output;
     
        # Return the updated ArchetypeInstanceJson
        return $ArchetypeInstanceJson;
    }
    catch {
        Write-Host "An error ocurred while running Start-CustomScript";
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
            Write-Debug "Archetype instance name not provided as input parameter, attempting to retrieve it from Parameters.InstanceName";

            if ($null -eq $ArchetypeInstance.Parameters.InstanceName -or `
                [string]::IsNullOrEmpty($ArchetypeInstance.Parameters.InstanceName)) {
                throw "Archetype instance name not provided as input parameter or in Parameters.InstanceName";
            }

            return $ArchetypeInstance.Parameters.InstanceName;
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
Function New-ConfigurationInstance {
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

            Write-Debug "File path is: $FilePath";

            $global:configurationBuilder = `
                [ConfigurationBuilder]::new(
                    $null,
                    $FilePath);

            # Generate archetype Instance from archetype
            # definition.
            # Additionally pass a callback function to
            # configuration builder, this callback will
            # add subscription and tenant ids to the configuration
            # instance.
            # Since configuration builder is agnostic
            # on the configuration being created, adding code
            # to add subscription and tenant ids does not belong
            # to configuration builder, therefore this code is
            # passed as a callback
            $configurationInstance = `
                $configurationBuilder.BuildConfigurationInstance(${function:\Add-SubscriptionAndTenantIds});

            Write-Debug "Configuration instance: $(ConvertTo-Json $configurationInstance -Depth 100)"

            if(![string]::IsNullOrEmpty($CacheKey)) {
                # Let's cache the archetype instance
                $cacheDataService.SetByKey(
                    $CacheKey,
                    $configurationInstance);
            }

            Write-Debug "Configuration instance properly cached, using key: $CacheKey";
        }
        return $configurationInstance;
    }
    catch {
        Write-Host "An error ocurred while running New-ConfigurationInstance";
        Write-Host $_;
        throw $_;
    }
}

Function Add-SubscriptionAndTenantIds {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]
        $ConfigurationInstance
    )

    try {
        if($null -ne $ConfigurationInstance.Parameters) {
            $subscriptionName = `
                $ConfigurationInstance.Parameters.Subscription;

            $additionalInformation = @{
                SubscriptionId = $ConfigurationInstance.Subscriptions.$subscriptionName.SubscriptionId
                TenantId = $ConfigurationInstance.Subscriptions.$subscriptionName.TenantId
            }

            if ($null -eq $ConfigurationInstance.Parameters.SubscriptionId `
                -and `
                $null -eq $ConfigurationInstance.Parameters.TenantId) {

                Write-Debug "$(ConvertTo-Json $ConfigurationInstance)";
                Write-Debug "$(ConvertTo-Json $additionalInformation)";

                $ConfigurationInstance.Parameters | `
                    Add-Member `
                        -NotePropertyMembers $additionalInformation;
            }
            elseif ($null -ne $ConfigurationInstance.Parameters.SubscriptionId) {
                $ConfigurationInstance.Parameters.SubscriptionId = `
                    $additionalInformation.SubscriptionId;
            }
            elseif ($null -ne $ConfigurationInstance.Parameters.TenantId) {
                $ConfigurationInstance.Parameters.TenantId = `
                    $additionalInformation.TenantId;
            }
        }
    }
    catch {
        Write-Host "An error ocurred while running Add-SubscriptionAndTenantIds";
        Write-Host $_;
        throw $_;
    }
}

Function Invoke-Bootstrap {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $WorkingDirectory,
        [Parameter(Mandatory=$true)]
        [string]
        $ToolkitConfigurationFilePath,
        [Parameter(Mandatory=$true)]
        [string]
        $Mode
    )

    $ToolkitConfigurationFilePath = `
        Format-FilePathSpecificToOS -Path $ToolkitConfigurationFilePath;

    try {
        # Build toolkit configuration from file
        $toolkitConfigurationJson = `
            New-ConfigurationInstance `
                -FilePath $ToolkitConfigurationFilePath `
                -WorkingDirectory $WorkingDirectory;

        # Getting cache information from toolkit configuration
        $cacheStorageInformation = `
            Get-CacheStorageInformation `
                -ToolkitConfigurationJson $toolkitConfigurationJson;

        Write-Debug "Cache storage information is: $(ConvertTo-Json $cacheStorageInformation -Depth 100)";

        # Getting audit information from toolkit configuration
        $auditStorageInformation = `
            Get-AuditStorageInformation `
                -ToolkitConfigurationJson $toolkitConfigurationJson `
                -WorkingDirectory $WorkingDirectory;

        Write-Debug "Audit storage information is: $(ConvertTo-Json $auditStorageInformation -Depth 100)";

        # Validation Resource Group details are only needed in validate mode
        if($Mode -eq "validate") {
            # Getting validation resource group information from toolkit configuration
            $validationResourceGroupInformation = `
                Get-ValidationResourceGroupInformation `
                    -ToolkitConfigurationJson $toolkitConfigurationJson;

            Write-Debug "Validation Resource Group information is: $(ConvertTo-Json $validationResourceGroupInformation -Depth 100)";
        }

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
                    $auditStorageInformation.StorageAccountName
                    );

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
            # When initializing a local store, the return will be a path
            # where all the audit and state information will be stored
            $bootstrapAuditStoragePath = `
                $bootstrap.InitializeLocalStore();

            $factory = `
                New-FactoryInstance `
                    -AuditStorageType $auditStorageInformation.StorageType `
                    -CacheStorageType $cacheStorageInformation.StorageType `
                    -AuditStoragePath $bootstrapAuditStoragePath;

            Write-Debug "Bootstrap type: local storage, result is: $(ConvertTo-Json $bootstrapResults -Depth 100)";
        }
        # Not supported, throw an error
        else {
            throw "ToolkitComponents.Audit.StorageType not supported, currently supported types are: StorageAccount and Local";
        }

        # Return an object that wraps the factory and the validation resource group information. 
        return @{ "Factory" = $factory
            "ValidationResourceGroupInformation" = $ValidationResourceGroupInformation
        }
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
        $ModuleConfiguration,
        [Parameter(Mandatory=$true)]
        [string]
        $Mode
    )

    try {

        if ($null -eq $SubscriptionName) {
            # If there is no subscription name, it means
            # we might be creating one as part of the archetype
            # deployment (using a custom script)
            return $null;
        }
        else {
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

            # Use the Module Instance's Subscription information only in "deploy" mode. Otherwise, use the Archetype's Subscription information.
            Write-Debug "Let's check if module configuration is not null and has a Subscription property with a value different than null or empty.";
            if (($null -ne $ModuleConfiguration) -and `
                $null -ne $subscriptionKey -and `
                ![string]::IsNullOrEmpty($ModuleConfiguration.$subscriptionKey) -and `
                $Mode -eq "deploy") {
                Write-Debug "Module instance configuration found and has a Subscription property, will use its values to run a deployment.";
                Write-Debug "Subscription name is: $($moduleConfiguration.$subscriptionKey)";

                $SubscriptionName = `
                    $moduleConfiguration.$subscriptionKey;
            }

            $subscriptionNameMatch = `
                $ArchetypeInstanceJson.$archetypeInstanceSubscriptions.Keys `
                    -match $SubscriptionName;
            if($null -ne $archetypeInstanceSubscriptions `
                -and $null -ne $subscriptionNameMatch) {
                # Retrieve case-sensitive key name from case-insensitive key name using match operation
                $SubscriptionName = $subscriptionNameMatch[0];
                $subscriptionInformation = `
                    $archetypeInstanceJson.$archetypeInstanceSubscriptions.$SubscriptionName;
            }

            Write-Debug "Subscription information is: $(ConvertTo-Json $subscriptionInformation)";
            return $subscriptionInformation;
        }
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
        $ToolkitConfigurationJson,
        [Parameter(Mandatory=$false)]
        [string]
        $WorkingDirectory
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
                    $WorkingDirectory;
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

Function Get-ValidationResourceGroupInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]
        $ToolkitConfigurationJson
    )

    try {
        $validationResourceGroupInformation = @{};

        # At a minimum, we expect the configuration object to have an property named "ValidationResourceGroup" of type object
        # and a child property named "Name" of type string. Other properties including Location and Tags are optional.
        if ($null -ne $ToolkitConfigurationJson.Configuration.ValidationResourceGroup -and `
            ![string]::IsNullOrEmpty($ToolkitConfigurationJson.Configuration.ValidationResourceGroup.Name)) {
            # Let's get the Validation Resource Group information
            
            $validationResourceGroupInformation.Name = $ToolkitConfigurationJson.Configuration.ValidationResourceGroup.Name;
            $validationResourceGroupInformation.Location = $ToolkitConfigurationJson.Configuration.ValidationResourceGroup.Location;
            $validationResourceGroupInformation.Tags = $ToolkitConfigurationJson.Configuration.ValidationResourceGroup.Tags;
        }
        else {
            $validationResourceGroupInformation.Name = `
                Get-UniqueString($ArchetypeInstanceName);
        }

        return $validationResourceGroupInformation;
    }
    catch {
        Write-Host "An error ocurred while running Get-ValidationResourceGroupInformation";
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
        $ModuleConfigurationName,
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [string]
        $Operation
    )

    try {
        Write-Debug "About to search for Module Instance Name: $ModuleConfigurationName";
        $moduleConfiguration = `
            $ArchetypeInstanceJson.Orchestration.ModuleConfigurations | Where-Object -Property 'Name' -EQ $moduleConfigurationName;

        if ($null -ne $moduleConfiguration){
            Write-Debug "Module instance configuration found: $(ConvertTo-Json $moduleConfiguration -Depth 100)";

            # Let's check if we are updating an existing module
            if ($null -ne $moduleConfiguration.Updates) {

                $existingModuleConfigurationName = `
                    $moduleConfiguration.Updates;

                Write-Debug "Updating existing module: $existingModuleConfigurationName";

                # Let's check if the existing module exists:
                $existingModuleConfiguration = `
                    $ArchetypeInstanceJson.Orchestration.ModuleConfigurations | Where-Object -Property 'Name' -EQ $existingModuleConfigurationName;

                if ($null -eq $existingModuleConfiguration) {
                    throw "Existing module not found";
                }

                Write-Debug "Existing module found: $(ConvertTo-Json $existingModuleConfiguration -Depth 50)";

                $moduleConfiguration = `
                    Merge-ExistingModuleWithUpdatesModule `
                        -ModuleConfiguration $moduleConfiguration `
                        -ExistingModuleConfiguration $existingModuleConfiguration
            }

            $moduleConfiguration = `
                Resolve-ReferenceFunctionsInModuleConfiguration `
                    -ModuleConfiguration $moduleConfiguration `
                    -ArchetypeInstanceName $ArchetypeInstanceName `
                    -Operation $Operation

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

        $deploymentTemplate = `
            Get-DeploymentFileContents `
                -DeploymentConfiguration $DeploymentConfiguration `
                -DeploymentType "ARM" `
                -DeploymentFileType "template" `
                -ModuleConfigurationsPath $ModuleConfigurationsPath `
                -WorkingDirectory $WorkingDirectory;

        $isSubscriptionDeployment = `
            $false;

        # Check for the scope of the operation
        if($null -ne $deploymentTemplate -and `
            $deploymentTemplate.`
            Contains("subscriptionDeploymentTemplate")) {
            # If template schema contains the schema for
            # subscription, then the scope is set to
            # subscription
            $isSubscriptionDeployment = $true;
        }

        return @{
            Template = $deploymentTemplate
            IsSubscriptionDeployment = $isSubscriptionDeployment
        }
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
        $DeploymentType, # Possible values are ARM, Policies, RBAC
        [Parameter(Mandatory=$true)]
        [string]
        $DeploymentFileType, # Possible values are TemplatePath or ParametersPath
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

            $moduleRelativeFilePath = $ModuleConfiguration.ModuleDefinitionName

            if ($DeploymentType.ToLower() -eq "arm") {
                $moduleRelativeFilePath += "/$fileName";
            }
            elseif ($DeploymentType.ToLower() -eq "policies") {
                $moduleRelativeFilePath += "/Policy/$fileName";
            }
            elseif ($DeploymentType.ToLower() -eq "rbac") {
                $moduleRelativeFilePath += "/RBAC/$fileName";
            }
            else {
                throw "Deployment type not supported";
            }

            # Let's get a relative template path that is OS agnostic
            # We'll split based on slashes because it is our internal
            # delimiter for folders plus file name
            $normalizedRelativeFilePath = `
                New-NormalizePath `
                    -FilePaths $moduleRelativeFilePath.Split('/');

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
                Write-Debug "If the DeploymentFileType is template, returning null means that no deployment will get executed";
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
        [Parameter(Mandatory=$false)]
        [string]
        $ResourceGroupName,
        [Parameter(Mandatory=$false)]
        [string]
        $ResourceGroupLocation,
        [Parameter(Mandatory=$false)]
        [object]
        $Tags,
        [Parameter(Mandatory=$true)]
        [switch]
        $Validate
    )

    try {
        $deploymentService.CreateResourceGroup(
            $resourceGroupName,
            $resourceGroupLocation,
            $Tags);
    }
    catch {
        Write-Host "An error ocurred while running New-ResourceGroup";
        Write-Host $_;
        throw $_;
    }
}

Function New-AzureResourceManagerDeployment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $TenantId,
        [Parameter(Mandatory=$true)]
        [string]
        $SubscriptionId,
        [Parameter(Mandatory=$false)]
        [string]
        $ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]
        $DeploymentTemplate,
        [Parameter(Mandatory=$false)]
        [string]
        $DeploymentParameters,
        [Parameter(Mandatory=$true)]
        $ModuleConfiguration,
        [Parameter(Mandatory=$true)]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [string]
        $Location,
        [Parameter(Mandatory=$true)]
        [switch]
        $Validate,
        [string]
        $AzureManagementUrl
    )

    try {

        # Merge the template's parameters json file with
        # any OverrideParameters
        $DeploymentParameters = `
            Merge-Parameters `
                -DeploymentParameters $DeploymentParameters `
                -ModuleConfiguration $ModuleConfiguration `
                -ArchetypeInstanceName $ArchetypeInstanceName `
                -Operation @{ "False" = "deploy"; "True" = "validate"; }[$Validate.ToString()];

        Write-Debug "Overridden parameters are: $DeploymentParameters";

        if($Validate.IsPresent) {
            Write-Debug "Validating the template";
            return `
                $deploymentService.ExecuteValidation(
                    $TenantId,
                    $SubscriptionId,
                    $ResourceGroupName,
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
                    $Location,
                    $AzureManagementUrl);
        }
    }
    catch {
        Write-Host "An error ocurred while running ModuleConfigurationDeployment.New-AzureResourceManagerDeployment";
        Write-Host $_;
        throw $_;
    }
}

Function New-DeploymentStateInformation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [guid]
        $AuditId,
        [Parameter(Mandatory=$false)]
        [string]
        $DeploymentId,
        [Parameter(Mandatory=$false)]
        [string]
        $DeploymentName,
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [string]
        $ModuleConfigurationName,
        [Parameter(Mandatory=$false)]
        [object]
        $ResourceStates,
        [Parameter(Mandatory=$false)]
        [object]
        $ResourceIds,
        [Parameter(Mandatory=$false)]
        [string]
        $ResourceGroupName,
        [Parameter(Mandatory=$false)]
        [object]
        $DeploymentTemplate,
        [Parameter(Mandatory=$false)]
        [object]
        $DeploymentParameters,
        [Parameter(Mandatory=$false)]
        [object]
        $DeploymentOutputs,
        [Parameter(Mandatory=$false)]
        [string]
        $TenantId,
        [Parameter(Mandatory=$false)]
        [string]
        $SubscriptionId,
        [Parameter(Mandatory=$false)]
        [object]
        $Policies,
        [Parameter(Mandatory=$false)]
        [object]
        $RBAC,
        [Parameter(Mandatory=$false)]
        [switch]
        $Validate
    )
    try {
        if(-not $Validate.IsPresent) {
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
        else {
            return $null;
        }
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
        [string]
        $TenantId,
        [Parameter(Mandatory=$true)]
        [string]
        $SubscriptionId,
        [Parameter(Mandatory=$true)]
        [object]
        $ArchetypeInstance,
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$false)]
        [switch]
        $Validate
    )

    try {
        if(-not $Validate.IsPresent) {
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
        else {
            return [Guid]::Empty;
        }
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
        $Outputs,
        [Parameter(Mandatory=$false)]
        [switch]
        $Validate
    )

    try {
        if(-not $Validate.IsPresent) {
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


                Write-Debug "Adding Output $(ConvertTo-Json $cacheValue -Depth 50) to $cacheKey";

                # Call Add-ItemToCache function to cache them
                # Safe to do .Value because we are caching deployment outputs
                # all deployment outputs contains a Type and Value properties.
                Add-ItemToCache `
                    -Key $cacheKey `
                    -Value $cacheValue `
                    -Validate:$($Validate.IsPresent);
            }
        }
    }
    catch {
        Write-Host "An error ocurred while running New-NormalizePath";
        Write-Host $_;
        throw $_;
    }
}

Function Add-ItemToCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Key,
        [Parameter(Mandatory=$false)]
        [object]
        $Value,
        [Parameter(Mandatory=$false)]
        [switch]
        $Validate
    )

    try {
        if(-not $Validate.IsPresent) {
            $cacheDataService.SetByKey(
                $Key,
                $Value);
        }
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

Function Merge-Parameters {
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

    try {
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
        if($moduleConfiguration.Keys -eq "OverrideParameters") {
            # Retrieve the module instance override parameters
            $overrideParameters = $moduleConfiguration.OverrideParameters;
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
    catch {
        Write-Host "An error ocurred while running Get-ItemFromCache";
        Write-Host $_;
        throw $_;
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

    try {
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
    catch {
        Write-Host "An error ocurred while running Get-ItemFromCache";
        Write-Host $_;
        throw $_;
    }
}

Function Resolve-ReferenceFunctionsInModuleConfiguration() {
    [CmdletBinding()]
    param(
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

    try {
        # Regex to match for the following format:
        # reference(archetypeInstance.moduleConfiguration.outputName)
        $fullReferenceFunctionMatchRegex = 'reference\((.*)\)';

        # Convert object to string
        $ModuleConfigurationContent = `
            ConvertTo-Json `
                -InputObject $ModuleConfiguration `
                -Depth 50;

        # Resolve only during deploy operation and if reference function is
        # found
        if($Operation -eq "deploy" -and `
            $ModuleConfigurationContent -match $fullReferenceFunctionMatchRegex) {

                return `
                    (Get-OutputReferenceValue `
                    -ParameterValue $ModuleConfiguration `
                    -ArchetypeInstanceName $ArchetypeInstanceName).result;

        }
        else {
            # When in validate mode or if no reference function is found, return as-is.
            return `
                $ModuleConfiguration;
        }
    }
    catch {
        Write-Host "An error ocurred while running Get-ItemFromCache";
        Write-Host $_;
        throw $_;
    }
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

    try {
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
            if($null -ne $cacheValue)
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

            Write-Debug "Output is: $(ConvertTo-Json $resolvedOutput)";
            Write-Debug "Output type is $($resolvedOutput.GetType())";

            # Did we resolve the output?
            if ($resolvedOutput `
                -and $resolvedOutput -is [object[]]){
                Write-Debug "Replacing an array";

                # Since is an array, let's replace the reference function
                # including double quotes or single quotes
                $tempfullReferenceFunctionString1 = `
                    """$fullReferenceFunctionString""";

                Write-Debug "reference with double quotes is: $tempfullReferenceFunctionString1"

                $tempfullReferenceFunctionString2 = `
                    "'$fullReferenceFunctionString'";

                Write-Debug "reference with single quotes is: $tempfullReferenceFunctionString2"

                $resolvedOutputString = `
                        ConvertTo-Json `
                            -InputObject $resolvedOutput `
                            -Depth 100 `
                            -Compress;

                $parameterValueString = `
                    $parameterValueString.Replace(
                        $tempfullReferenceFunctionString1,
                        $resolvedOutputString
                    ).Replace(
                        $tempfullReferenceFunctionString2,
                        $resolvedOutputString
                    );
            }
            elseif($resolvedOutput `
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
    catch {
        Write-Host "An error ocurred while running Get-ItemFromCache";
        Write-Host $_;
        throw $_;
    }
}

Function Format-ResolvedOutput() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $OutputValue
    )

    try {
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
    catch {
        Write-Host "An error ocurred while running Get-ItemFromCache";
        Write-Host $_;
        throw $_;
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

    try {
        Write-Debug "All filters: $(ConvertTo-Json $Filters)";

        # Start by retrieving all the outputs for the archetype and/or module
        # instance combination

        $crossArchetypeOutputs = $false;

        if($Filters.Count -ge 3) {
            # If there are three segments, we are in a cross archetype scenario
            $archetypeInstanceName = $Filters[0];
            $moduleConfigurationName = $Filters[1];
            $crossArchetypeOutputs = $true;
        }
        elseif($Filters.Count -eq 2) {
            # If there are two segments, we are in the same archetype scenario
            $archetypeInstanceName = $ArchetypeInstanceName;
            $moduleConfigurationName = $Filters[0];
        }
        else {
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

        Write-Debug "Output to be searched: $outputParameterName";

        if ($null -ne $allOutputs) {
            Write-Debug "Outputs found, proceed to cache the values";

            # Let's format the deployment outputs, this function
            # will create a Powershell Array when a JArray is found
            # as a deployment output. This is true when a deployment
            # output has a type = "array"

            $allOutputs = `
                Format-DeploymentOutputs `
                    -DeploymentOutputs $allOutputs;

            Write-Debug "Formatted deployment outputs: $(ConvertTo-Json $allOutputs -Depth 10)";

            $allOutputs.Keys | ForEach-Object {
                $parameterName = $_;
                # Doing .Value because is a deployment output parameter
                $parameterValue = $allOutputs.$parameterName.Value;

                if ($crossArchetypeOutputs) {
                    $cacheKey = `
                        "$archetypeInstanceName.$moduleConfigurationName.$parameterName";
                }
                else {
                    $cacheKey = `
                        "$moduleConfigurationName.$parameterName";
                }

                Write-Debug "Cache Key: $cacheKey";
                Write-Debug "Cache Value is: $(ConvertTo-Json $parameterValue)";
                # Cache the retrieved value by calling set method on cache data service with key and value
                $cacheDataService.SetByKey(
                    $cacheKey,
                    $parameterValue);
            }

            # Find the specific output
            if($allOutputs.Keys -eq $outputParameterName) {
                $output = $allOutputs.$outputParameterName.Value;

                Write-Debug "Ouput found, parameter: $outputParameterName and its value is: $(ConvertTo-Json $output)";
                Write-Debug "Output type is: $($output.GetType())";
                return $output;
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
    catch {
        Write-Host "An error ocurred while running Get-ItemFromCache";
        Write-Host $_;
        throw $_;
    }
}

Function Remove-ValidationResourceGroup() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$false)]
        [object]
        $ValidationResourceGroupInformation
    )

    $resourceGroupFound = `
        Assert-ValidationResourceGroup `
            -ArchetypeInstanceName $ArchetypeInstanceName `
            -ValidationResourceGroupInformation $ValidationResourceGroupInformation;

    if($resourceGroupFound -eq $true) {

        $resourceGroupName = $ValidationResourceGroupInformation.Name;

        Start-ExponentialBackoff `
            -Expression { Remove-AzResourceGroup `
                            -Name $resourceGroupName `
                            -Force; }

        Write-Host "Validation ResourceGroup $resourceGroupName deleted."
    }
    else {
        Write-Host "Validation ResourceGroup $resourceGroupName does not exists."
    }
}

Function Assert-ValidationResourceGroup() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$true)]
        [object]
        $ValidationResourceGroupInformation
    )

    $resourceGroup = `
        Get-ValidationResourceGroup `
            -ArchetypeInstanceName $ArchetypeInstanceName `
            -ValidationResourceGroupInformation $ValidationResourceGroupInformation;

    if($null -ne $resourceGroup) {
        return $true;
    }
    else {
        return $false;
    }

}

Function Get-ValidationResourceGroup() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ArchetypeInstanceName,
        [Parameter(Mandatory=$false)]
        [object]
        $ValidationResourceGroupInformation
    )

    $resourceGroupName = $ValidationResourceGroupInformation.Name;

    return `
        Get-AzResourceGroup $resourceGroupName `
            -ErrorAction SilentlyContinue;
}

# Entry point script, used when invoking ModuleConfigurationDeployment.ps1
# In order to allow the module to be imported (Import-Module), let's
# verify if the mandatory parameters are not passed.
if (![string]::IsNullOrEmpty($DefinitionPath)) {

    # Start transcript only if the flag is set to true
    if($GenerateTranscript.IsPresent -eq $true) {
        $TranscriptPath = `
            ConvertTo-AbsolutePath `
                -Path $TranscriptPath `
                -RootPath $(Get-WorkingDirectory -WorkingDirectory $WorkingDirectory) `
                -SkipFilePathExistenceCheck;
        Start-Transcript -Path $TranscriptPath;
    }
    try {
        if($TearDownEnvironment.IsPresent) {
            Start-TearDownEnvironment `
                -ArchetypeInstanceName $ArchetypeInstanceName `
                -DefinitionPath $DefinitionPath `
                -ToolkitConfigurationFilePath $ToolkitConfigurationFilePath `
                -ModuleConfigurationName $ModuleConfigurationName `
                -WorkingDirectory $WorkingDirectory
        }
        else {
            Start-Deployment `
                -DefinitionPath $DefinitionPath `
                -ToolkitConfigurationFilePath $ToolkitConfigurationFilePath `
                -ArchetypeInstanceName $ArchetypeInstanceName `
                -ModuleConfigurationName $ModuleConfigurationName `
                -WorkingDirectory $WorkingDirectory `
                -Validate:$($Validate.IsPresent);
        }
    }
    Catch {
        Write-Host "Deployment exited unexpectedly."
    }
    Finally {
        # Stop transcript only if the flag is set to true
        if($GenerateTranscript.IsPresent -eq $true) {
            Stop-Transcript;
        }
    }
}



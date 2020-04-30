# **To deploy Azure Virtual Datacenter for VDI**

MS-VDI environment has Azure resources that are dependent on "Shared Services". This follows HUB and SPOKE model, with "Shared Services" as HUB and "MS-VDI" as SPOKE.

**If [Shared Services](../../Environments/SharedServices) are not yet deployed, please deploy Shared Services before deploying [MS-VDI](../../Environments/MS-VDI) archetypes provided in the toolkit.**

## Setting the Environmental variables

All the settings for Environmental variables for Shared Services will be reused for MS-VDI deployment. First set up, deploy Shared Services and continue for MS-VDI

## Setting the Parameters

Any application specific parameters updates should be done in the [parameters.json](../../Environments/MS-VDI/parameters.json) file such as IP address, subnet names, subnet range, secrets etc.

## Deploying the MS-VDI environment

1. Return to the running Docker container from earlier in the quickstart.
1. If you have not already done so, run `Connect-AzAccount -Tenant "[TENANT_ID]" -SubscriptionId "[SUBSCRIPTION_ID]" -EnvironmentName "[AZURE_ENVIRONMENT]"` to login and set an Azure context.
1. To deploy the entire MS-VDI environment, you can run a single command:

    ``` PowerShell
    ./Orchestration/OrchestrationService/ModuleConfigurationDeployment.ps1 -DefinitionPath ./Environments/MS-VDI/definition.json
    ```

The toolkit will begin deploying the constituent modules and the status will be sent to the terminal.
Open the [Azure portal](https://portal.azure.us) and you can check the status of the invididual deployments. Azure portal link will be based on azure environment.

## Deploying individual modules

If you prefer you can deploy the constituent modules for MS-VDI individually.
The following is the series of commands to execute.

``` PowerShell
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "VirtualNetworkSPOKE"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "VirtualNetworkPeeringHub"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "VirtualNetworkPeeringSpoke"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "DiagnosticStorageAccount"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "EnableServiceEndpointOnDiagnosticStorageAccount"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "LogAnalytics"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "KeyVault"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "ArtifactsStorageAccount"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "UploadScriptsToArtifactsStorage"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "JumpboxASG"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\MS-VDI\definition.json -ModuleConfigurationName "WindowsVM"
```

**NOTE:**

1. If deployment reports, unable to find deployment storage account, it could be that PowerShell is not connected to Azure.
2. Open a new PowerShell/Docker instance if there was any changes to files in Environments folder

### **Teardown the environment**

``` PowerShell
./Orchestration/OrchestrationService/ModuleConfigurationDeployment.ps1 -TearDownEnvironment -DefinitionPath ./Environments/MS-VDI/definition.json
```

Note: This is the same command you used to deploy except that you include ` -TearDownEnvironment`.
It uses the same configuration, so if you change the configuration the tear down may not execute as expected.

### **Remove vdc-toolkit-rg**

Teardown removes only the resources deployed from VDC toolkit orchestration but do not actually remove the resource group (vdc-toolkit-rg) and storage accounts created by VDC toolkit deployment.
vdc-toolkit-rg

Use the Azure Cli to remove the resource group and the storage accounts. Find the storage account name from the vdc-toolkit-rg resource group.

``` AzureCli
az account set --subscription [SUBSCRIPTION_ID]

az storage container legal-hold clear --resource-group vdc-toolkit-rg --account-name [STORAGE_ACCOUNT_NAME] --container-name deployments --tags audit

az storage container legal-hold clear --resource-group vdc-toolkit-rg --account-name [STORAGE_ACCOUNT_NAME] --container-name audit --tags audit
```

### **Remove KeyVault**

For safety reasons, the key vault will not be deleted. Instead, it will be set to a _removed_ state. This means that the name is still considered in use. To fully delete the key vault, use:

``` PowerShell
Get-AzKeyVault -InRemovedState | ? { Write-Host "Removing vault: $($_.VaultName)"; Remove-AzKeyVault -InRemovedState -VaultName $_.VaultName -Location $_.Location -Force }
```

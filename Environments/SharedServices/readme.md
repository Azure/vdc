# **To deploy Azure Virtual Datacenter for Shared Services**

Deployment steps for [SharedServices](../../Environments/SharedServices) archetypes provided in the toolkit.
The documentation applies to manually building and running the docker instance. For github action setup click
[GitHub Action for VDC](../../.github/workflows/README.md)

### Clone the repository

These steps assume that the `git` command is on your path.

1. Open a terminal window
2. Navigate to a folder where you want to store the source for the toolkit. For, e.g. `c:\git`, navigate to that folder.
3. Run `git clone https://github.com/RKSelvi/vdc.git`. This will clone the GitHub repository in a folder named `vdc`.
4. Run `cd vdc` to change directory in the source folder.
5. Run `git checkout master` to switch to the branch with the current in-development version of the toolkit.

### Build the Docker image

1. Ensure that the [Docker daemon](https://docs.docker.com/config/daemon/) is running. If you are new to Docker, the easiest way to do this is to install [Docker Desktop](https://www.docker.com/products/docker-desktop).
1. Open a terminal window
1. Navigate to the folder where you cloned the repository. _The rest of the quickstart assumes that this path is `C:\git\vdc\`_
1. Run `docker build . -t vdc:latest` to build the image.

### Run the toolkit container

After the image finishing building, you can run it using:

`docker run -it --entrypoint="pwsh" --rm -v C:\git\vdc\Config:/usr/src/app/Config -v C:\git\vdc\Environments:/usr/src/app/Environments -v C:\git\vdc\Modules:/usr/src/app/Modules vdc:latest`

A few things to note:

- You don't need to build the image every time you want to run the container. You'll only need to rebuild it if there are changes to the source (primarily changes in the `Orchestration` folder).
- The `docker run` command above will map volumes in the container to volumes on the host machine. This will allow you to directly modify files in these directories (`Config`,`Environments`, and `Modules`).

When the container starts, you will see the prompt
`PS /usr/src/app>`

## Configure the toolkit

To configure the toolkit for this quickstart, we will need to collect the following information.

You'll need:

- A subscription for the toolkit to use for logging and tracking deployment.
- The associated tenant id of the Azure Active Directory associated with those subscriptions.
- The object id of the user account that you'll use to run the deployment.
- The object id of a [service principal](https://docs.microsoft.com/azure/active-directory/develop/howto-create-service-principal-portal) that Azure DevOps can use for deployment. This is only for CI/CD pipeline
- An organization name for generating a prefix for naming resources.
- The desired username and password for the Active Directory domain admin that will be created. Active Directory is not deployed now.
- The desired password of the Windows jumpbox.
- The [public ssh key](https://docs.microsoft.com/azure/virtual-machines/linux/mac-create-ssh-keys) for accessing the Linux jumpbox.

Note: You can use a single subscription. You'll just need to provide the same subscription id in multiple locations in the configuration.

### Collecting user object id and tentant id

You can get your user object id and tenant id in the portal or by using command line utitilies.

Using Azure PowerShell:

1. Run `Connect-AzAccount -Tenant "[TENANT_ID]" -SubscriptionId "[SUBSCRIPTION_ID]" -EnvironmentName "[AZURE_ENVIRONMENT]"` to login and set an Azure context. For Azure Commercial environment "AzureCloud" & for Azure Government "AzureUSGovernment"
2. Run `Get-AzContext | % { Get-AzADUser -UserPrincipalName $($_.Account.Id) } | select Id` to get the user object id.
3. Run `Get-AzContext | select Tenant` to get the tenant id.
  
#### Environmental variables

The toolkit uses environmental variables instead of configuration files to help avoid the accidental inclusion of secrets into your source control. In the context of a CI/CD pipeline, these values would be retrieved from a key vault. For GitHub Actions workflow this will be coming from GitHub Secrets.

Set these environmental variables by substituting the actual values in the script below.
Copy and paste this script into PowerShell to execute it.

Note: The first two variables are set with the content of the configuration files we just modified. The path will not resolve correctly unless you are in `/usr/src/app` directory. 

```PowerShell
$ENV:ORGANIZATION_NAME = "[ORGANIZATION_NAME]"
$ENV:AZURE_ENVIRONMENT_NAME = "[AZURE_ENVIRONMENT]"
$ENV:AZURE_LOCATION = "[AZURE_REGION]"
$ENV:TENANT_ID = "[TENANT_ID]"
$ENV:SUBSCRIPTION_ID = "[SUBSCRIPTION_ID]"
$ENV:KEYVAULT_MANAGEMENT_USER_ID  = "[KEY_VAULT_MANAGEMENT_USER_ID]"
$ENV:DEVOPS_SERVICE_PRINCIPAL_USER_ID = "[SERVICE_PRINCIPAL_USER_ID]"
$ENV:DOMAIN_ADMIN_USERNAME = "[DOMAIN_ADMIN_USER_NAME]"
$ENV:DOMAIN_ADMIN_USER_PWD = "[DOMAIN_ADMIN_USER_PASSWORD]"
$ENV:ADMIN_USER_NAME = "[VM_ADMIN_USER_NAME]"
$ENV:ADMIN_USER_PWD = "[VM_ADMIN_USER_PASSWORD]"
$ENV:AZURE_DISCOVERY_URL = "https://management.azure.com/metadata/endpoints?api-version=2019-05-01"
$ENV:ADMIN_USER_SSH = "[SSH_KEY]"
```

**NOTE:** Examples to setting the env variables

- "[ORGANIZATION_NAME]"
  - Abbreviation of your org (for e.g. contoso) with **NO SPACES**
  - Must be 10 characters or less
- "[AZURE_ENVIRONMENT]"
  - For Azure Commercial
    - "AzureCloud"
  - For Azure Government
    - "AzureUSGovernment"
- "[AZURE_REGION]" - Depending on the Azure Enviroment, provide Azure regions. For e.g.
  - Azure public cloud
    - "East US"
    - "East US 2"
  - Azure Government
    - "USGov Virginia"
    - "USGov Iowa"
- "[KEY_VAULT_MANAGEMENT_USER_ID]"
  - User's GUID from AAD deploying the VDC toolkit
- "[SERVICE_PRINCIPAL_USER_ID]"
  - Used by CI/CD (not yet implemented). Can be same as KEY_VAULT_MANAGEMENT_USER_ID
- "[TENANT_ID]" - Tenant's GUID
- "[SUBSCRIPTION_ID]" - Subscription's GUID
- "[DOMAIN_ADMIN_USER_NAME]"
  - Domain user name - will be used for AD deployment and not yet included in current deployment
- "[DOMAIN_ADMIN_USER_PASSWORD]"
  - Domain user password - will be used for AD deployment and not yet included in current deployment. Follow the [guidelines](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm) for setting the password.
- "[VM_ADMIN_USER_NAME]"
  - VM log in username
- "[VM_ADMIN_USER_PASSWORD]"
  - VM user password. Follow the [guidelines](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq#what-are-the-password-requirements-when-creating-a-vm) for setting the password.
- "[SSH_KEY]"
  - Needs to be a valid public ssh rsa key for SSH to linux box
  
To use the above script:

1. Return to the running Docker container from earlier in the quickstart.
2. Confirm that you are in the `/usr/src/app` directory.
3. Make a copy of the above script and replace the necessary values.
4. Copy the script into the clipboard and paste it in the terminal.
5. Verify that the enviromental variables are set by running `env` to view the current values.

#### Pre-req script
##### This script will ensure that the configuration files are updated with your environment variables.

  ``` PowerShell
  ./Orchestration/OrchestrationService/Pre_req_script.ps1
  ```
  **You will need to run the cleanup script after you are done deploying the modules to ensure your secret values are not passed into the GitHub repository.**

#### Parameters

Any application specific parameters updates should be done in the [parameters.json](../../Environments/SharedServices/parameters.json) file such as IP address, subnet names, subnet range, secrets etc.

## Deploying the Shared Services environment

1. Return to the running Docker container from earlier in the quickstart.
1. If you have not already done so, run `Connect-AzAccount -Tenant "[TENANT_ID]" -SubscriptionId "[SUBSCRIPTION_ID]" -EnvironmentName "[AZURE_ENVIRONMENT]"` to login and set an Azure context.
1. To deploy the entire Shared Services environment, you can run a single command:

    ``` PowerShell
    ./Orchestration/OrchestrationService/ModuleConfigurationDeployment.ps1 -DefinitionPath ./Environments/SharedServices/definition.json
    ```

The toolkit will begin deploying the constituent modules and the status will be sent to the terminal.
Open the [Azure portal](https://portal.azure.us) and you can check the status of the invididual deployments. Azure portal link will be based on azure environment.

## Deploying individual modules

If you prefer you can deploy the constituent modules for Shared Services individually.
The following is the series of commands to execute.

``` PowerShell
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "AzureFirewall"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "VirtualNetwork"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "AzureSecurityCenter"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "NISTControls"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "AutomationAccounts"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "DomainControllerASG"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "DiagnosticStorageAccount"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "EnableServiceEndpointOnDiagnosticStorageAccount"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "LogAnalytics"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "KeyVault"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "ArtifactsStorageAccount"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "UploadScriptsToArtifactsStorage"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "JumpboxASG"
        .\Orchestration\OrchestrationService\ModuleConfigurationDeployment.ps1 -DefinitionPath .\Environments\SharedServices\definition.json -ModuleConfigurationName "SharedServicesNSG"
```

**NOTE:**

1. If deployment reports, unable to find deployment storage account, it could be that PowerShell is not connected to Azure.
2. Open a new PowerShell/Docker instance if there were any changes to files in Environments folder

### **Teardown the environment**

``` PowerShell
./Orchestration/OrchestrationService/ModuleConfigurationDeployment.ps1 -TearDownEnvironment -DefinitionPath ./Environments/SharedServices/definition.json
```

Note: This is the same command you used to deploy except that you include ` -TearDownEnvironment`.
It uses the same configuration, so if you change the configuration the tear down may not execute as expected.

### Cleanup script

#### This script will make sure all the environment variable values are not stored in your configuration files. Please run this after you are done deploying the modules. Usually you will run this script when you are about to exit your container.

``` PowerShell
  ./Orchestration/OrchestrationService/Cleanup_Script.ps1
  ```

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

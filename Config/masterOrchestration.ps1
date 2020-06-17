# VDC Master Script

## ONLY EDIT THE BELOW LINE (LINE 4)##
$inputFile = (Get-Content -Path C:\inputFile.json) | ConvertFrom-Json 

# Set the variables that will not change through the deployments of the VDC toolkit
$env:numShrdSvcs = $inputFile.sharedservices.Count
$env:numMSVDI = $inputFile.MSVDI.Count
$ENV:AZURE_DISCOVERY_URL = $inputFile.azureDiscoveryURL
$ENV:AZURE_SENTINEL = $inputFile.azureSentinel
$ENV:ORGANIZATION_NAME = $inputFile.organizationName
$ENV:AZURE_ENVIRONMENT_NAME = $inputFile.azureEnvironmentName
$ENV:TENANT_ID = $inputFile.tenantID
$ENV:HUB_SUB_ID = $inputFile.SharedServices.hub1.subscriptionID
#Location for artifact storage account
$ENV:ARTIFACT_LOCATION = $inputFile.SharedServices.hub1.location

Write-Host "Welcome to the VDC toolkit deployment. Starting the deployment for $ENV:ORGANIZATION_NAME organization. " -ForegroundColor Green
Write-Host `n"You choose to deploy $ENV:numShrdSvcs Shared Service environments." -ForegroundColor Cyan

Write-Host `n"You choose to deploy $ENV:numMSVDI MS-VDI environments." -ForegroundColor Cyan


Function Get-newEnvVariablesSS {
# The below arrays will hold all the env variables for each MS-VDI deployment

$adminUserPWD=@()
$domainAdminUsername=@()
$domainAdminPWD=@()

# The loop below will determine all the env variables for each deployment
For ($i=0; $i -lt $env:numShrdSvcs; $i++) {
    $int = $i+1
    $hub = "hub" + $int
    Write-Host `n"Enter the following secrets for $hub :" -Foregroundcolor Cyan

    $ADMIN_USER_PWD = Read-Host -Prompt "What is the VM Admin Password for the $hub deployment? `nEnter 'Random' for a random password"
    $adminUserPWD += $ADMIN_USER_PWD

    $DOMAIN_ADMIN_USERNAME = Read-Host -Prompt "What is the Domain Account UserName for the $hub deployment?"
    $domainAdminUsername += $DOMAIN_ADMIN_USERNAME

    $DOMAIN_ADMIN_USER_PWD = Read-Host -Prompt "What is the Domain Account Admin Password for the $hub deployment? `nEnter 'Random' for a random password"
    $domainAdminPWD += $DOMAIN_ADMIN_USER_PWD
 

   
    }
    return $adminUserPWD, $domainAdminUsername, $domainAdminPWD
 }
 
Function Get-newEnvVariablesMSVDI {
# The below arrays will hold all the env variables for each MS-VDI deployment

$adminUserPWDMsVDI=@()
$domainAdminUsernameMsVDI=@()
$domainAdminPWDMsVDI=@()

# The loop below will determine all the env variables for each deployment
For ($i=0; $i -lt $env:numMSVDI; $i++) {
    $int = $i+1
    $msvdi = "MSVDI" + $int
    Write-Host `n"Enter the following secrets for $msvdi :" -Foregroundcolor Cyan

    $ADMIN_USER_PWD = Read-Host -Prompt "What is the VM Admin Password for the $msvdi deployment? `nEnter 'Random' for a random password"
    $adminUserPWDMsVDI += $ADMIN_USER_PWD

    $DOMAIN_ADMIN_USERNAME = Read-Host -Prompt "What is the Domain Account UserName for the $msvdi deployment?"
    $domainAdminUsernameMsVDI += $DOMAIN_ADMIN_USERNAME

    $DOMAIN_ADMIN_USER_PWD = Read-Host -Prompt "What is the Domain Account Admin Password for the $msvdi deployment? `nEnter 'Random' for a random password"
    $domainAdminPWDMsVDI += $DOMAIN_ADMIN_USER_PWD
 

   
    }
    return $adminUserPWDMsVDI, $domainAdminUsernameMsVDI, $domainAdminPWDMsVDI
 }


# Get env secrets for Shared Services
$adminUserPWD, $domainAdminUsername, $domainAdminPWD = Get-newEnvVariablesSS 


# Get env secrets for MSVDI 
$adminUserPWDMsVDI, $domainAdminUsernameMsVDI, $domainAdminPWDMsVDI = Get-newEnvVariablesMSVDI

For($i=0; $i -lt $env:numShrdSvcs; $i++) {
    $int = $i+1
    $hub = "hub$int"
 
    Write-Host `n"Setting Environment Variables for $hub" -ForegroundColor Green
    $ENV:AZURE_LOCATION = $inputFile.SharedServices.$hub.location
    $ENV:SUBSCRIPTION_ID = $inputFile.SharedServices.$hub.subscriptionID
    $ENV:KEYVAULT_MANAGEMENT_USER_ID = $inputFile.SharedServices.$hub.keyvaultobjectID
    $ENV:DEVOPS_SERVICE_PRINCIPAL_USER_ID = $inputFile.SharedServices.$hub.devopsID
    $ENV:ADMIN_USER_SSH = $inputFile.SharedServices.$hub.adminSSHPubKey
    $ENV:FolderName = $inputFile.SharedServices.$hub.folderName
    $ENV:ADMIN_USER_NAME = $inputFile.SharedServices.$hub.vmAdminUserName
    $ENV:ADMIN_USER_PWD = $adminUserPWD[$i]
    $ENV:DOMAIN_ADMIN_USER_PWD = $domainAdminPWD[$i]
    $ENV:DOMAIN_ADMIN_USERNAME = $domainAdminUsername[$i]

   
    Write-Host `n"Starting the deployment for $hub. Orchestration using directory folder: $ENV:FolderName"

    
    Write-Host $ENV:ADMIN_USER_NAME
    Write-Host $ENV:ADMIN_USER_PWD
    Write-Host $ENV:AZURE_LOCATION
    Write-Host $ENV:SUBSCRIPTION_ID
    Write-Host $ENV:FolderName
    Write-Host $ENV:AZURE_SENTINEL
    Write-Host $ENV:AZURE_DISCOVERY_URL
    Write-Host $ENV:ORGANIZATION_NAME
    Write-Host $ENV:DOMAIN_ADMIN_USER_PWD
    Write-Host $ENV:DOMAIN_ADMIN_USERNAME
    Write-Host $ENV:KEYVAULT_MANAGEMENT_USER_ID
    Write-Host $ENV:DEVOPS_SERVICE_PRINCIPAL_USER_ID
    Write-Host $ENV:AZURE_ENVIRONMENT_NAME
    Write-Host $ENV:ADMIN_USER_SSH
    Write-Host $ENV:TENANT_ID
    
    sleep -Seconds 5
    ./Orchestration/OrchestrationService/Pre_req_script.ps1
    sleep -Seconds 5
    ./Orchestration/OrchestrationService/ModuleConfigurationDeployment.ps1 -DefinitionPath ./Environments/$env:folderName/definition.json
    sleep -Seconds 5

    
}


For($i=0; $i -lt $env:numMSVDI; $i++) {
    $int = $i+1
    $MSVDI = "MSVDI$int"
 
    Write-Host `n"Setting Environment Variables for $MSVDI" -ForegroundColor Green
    $ENV:AZURE_LOCATION = $inputFile.MSVDI.$MSVDI.location
    $ENV:SUBSCRIPTION_ID = $inputFile.MSVDI.$MSVDI.subscriptionID
    $ENV:KEYVAULT_MANAGEMENT_USER_ID = $inputFile.MSVDI.$MSVDI.keyvaultobjectID
    $ENV:DEVOPS_SERVICE_PRINCIPAL_USER_ID = $inputFile.MSVDI.$MSVDI.devopsID
    $ENV:ADMIN_USER_SSH = $inputFile.MSVDI.$MSVDI.adminSSHPubKey
    $ENV:FolderName = $inputFile.MSVDI.$MSVDI.folderName
    $ENV:ADMIN_USER_NAME = $inputFile.MSVDI.$MSVDI.vmAdminUserName
    $ENV:ADMIN_USER_PWD = $adminUserPWD[$i]
    $ENV:DOMAIN_ADMIN_USER_PWD = $domainAdminPWD[$i]
    $ENV:DOMAIN_ADMIN_USERNAME = $domainAdminUsername[$i]

   
    Write-Host `n"Starting the deployment for $MSVDI. Orchestration using directory folder: $ENV:FolderName"

    
    ./Orchestration/OrchestrationService/Pre_req_script.ps1
    sleep -Seconds 5
    ./Orchestration/OrchestrationService/ModuleConfigurationDeployment.ps1 -DefinitionPath ./Environments/$env:Foldername/definition.json
    sleep -Seconds 5
    
    Write-Host $ENV:ADMIN_USER_NAME
    Write-Host $ENV:ADMIN_USER_PWD
    Write-Host $ENV:AZURE_LOCATION
    Write-Host $ENV:SUBSCRIPTION_ID
    Write-Host $ENV:FolderName
    Write-Host $ENV:AZURE_SENTINEL
    Write-Host $ENV:AZURE_DISCOVERY_URL
    Write-Host $ENV:ORGANIZATION_NAME
    Write-Host $ENV:DOMAIN_ADMIN_USER_PWD
    Write-Host $ENV:DOMAIN_ADMIN_USERNAME
    Write-Host $ENV:KEYVAULT_MANAGEMENT_USER_ID
    Write-Host $ENV:DEVOPS_SERVICE_PRINCIPAL_USER_ID
    Write-Host $ENV:AZURE_ENVIRONMENT_NAME
    Write-Host $ENV:ADMIN_USER_SSH
    Write-Host $ENV:TENANT_ID
 
}


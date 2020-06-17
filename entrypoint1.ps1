#!/usr/src/app
$null = Find-Module -Name Az | Install-Module -Force
$null = Install-Module Az.ResourceGraph -Force
$null = Install-Module -Name Az.Accounts -Force
$null = Install-Module -Name Pester -Force

$secpasswd = ConvertTo-SecureString $env:SERVICE_PRINCIPAL_PASS -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($env:SERVICE_PRINCIPAL, $secpasswd)

Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $env:TENANT_ID -Subscription $env:SUBSCRIPTION_ID -EnvironmentName $env:AZURE_ENVIRONMENT_NAME

Write-Host "Welcome to the Virtual Datacenter tool kit"

## Execute the Pre-req script for adding Sub ID, Tenant ID, and Location to the configuration files
Write-Host "Executing the pre-req script in the config files"
./Orchestration/OrchestrationService/Pre_req_script.ps1

## Add a quick sleep to make sure the config files are updated before entering the main script
Start-Sleep -s 5

## Enter the main script for deploying shared services
Write-Host "Starting the script for deploying your Shared Services"
./Orchestration/OrchestrationService/ModuleConfigurationDeployment.ps1 -DefinitionPath ./Environments/SharedServices/definition.json 

Write-Host "The deployment was succesfull if: Exit code $LASTEXITCODE == 0" -Verbose

## Enter the main script for teardown shared services
Write-Host "Starting the script for tearing down Shared Services"
./Orchestration/OrchestrationService/ModuleConfigurationDeployment.ps1 -TearDownEnvironment -DefinitionPath ./Environments/SharedServices/definition.json

## Run the cleanup script so that no values are retained in code for the config files
Write-Host "Executing the cleanup script"

./Orchestration/OrchestrationService/Cleanup_Script.ps1

Write-Host "The deployment was succesfull if: Exit code $LASTEXITCODE == 0" -Verbose

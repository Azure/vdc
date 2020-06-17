## Tear Down Environment
When tearing down spokes or shared services environments you must make sure to complete the following pre-reqs before running the teardown script

1. You must be in the correct directory where you first deployed the environments
2. You will need to set your environment variables listed below
    1. **$ENV:ORGANIZATION_NAME** = "jvgovern"
        - This must be the value used when deployed initially. 
    2. **$ENV:TENANT_ID** = "35f102bf-a2d5-4531-86a3-fb1ba0d6725e"
        - This must be the value used when deployed initially. 
    3. **$ENV:SUBSCRIPTION_ID** = "8780edd9-dcbd-47cd-8aef-6bc3820754a9"
        - This must be the **Sub ID of the environment you wish to tear down**.
    4. **$ENV:AZURE_ENVIRONMENT_NAME** = "AzureUSGovernment"
        - This must be the environment name if you used Gov or Commercial 
    5. $ENV:AZURE_LOCATION = "USGov Virginia"
        - Not sure yet
    6. $ENV:KEYVAULT_MANAGEMENT_USER_ID  = "cd21365a-be74-4e64-92e1-9dd6cd872f38"
        - This can be arbitrary 
    7. $ENV:DEVOPS_SERVICE_PRINCIPAL_USER_ID = "cd21365a-be74-4e64-92e1-9dd6cd872f38"
        - This can be arbitrary
    8. $ENV:AZURE_DISCOVERY_URL = "https://management.azure.com/metadata/endpoints?api-version=2019-05-01"
        - This can be arbitrary 
    9. $ENV:DOMAIN_ADMIN_USERNAME = "Arb"
        - This can be arbitrary
    10. $ENV:DOMAIN_ADMIN_USER_PWD = "Arb"
        - This can be arbitrary
    11. $ENV:AZURE_SENTINEL = "true"
        - This can be arbitrary
    12. $ENV:ADMIN_USER_NAME= "Arb"
        - This can be arbitrary
    13. $ENV:ADMIN_USER_PWD = "Arb"
        - This can be arbitrary
    14. $ENV:ADMIN_USER_SSH = "Arb"
        - This can be arbitrary
    15. **$ENV:HUB_SUB_ID** = "888888888888888"
        - This value needs to be the subscription ID for the HUB environment (master Shared Services)
        - If you are tearing down spokes this value can be arbitrary
    16. $ENV:ARTIFACT_LOCATION = 'Arb"
        - This should be arbitrary unless you want to delete the Artifact storage account
            - You should only delete this if you plan to tear down the entire vdc toolkit.
            - However, if you mistakenly delete the artifact RG any new vdc build will create a new one.

3. Next you will need to sign in to Azure using the following command
    - Connect-AzAccount -Tenant $env:TENANT_ID -SubscriptionId $env:SUBSCRIPTION_ID -EnvironmentName $env:AZURE_ENVIRONMENT_NAME
4. Run the pre-req script so that the proper config files are updated
    - .\Orchestration\OrchestrationService\Pre_req_script.ps1
5. ./Orchestration/OrchestrationService/ModuleConfigurationDeployment.ps1 -TearDownEnvironment -DefinitionPath ./Environments/MS-VDI/definition.json

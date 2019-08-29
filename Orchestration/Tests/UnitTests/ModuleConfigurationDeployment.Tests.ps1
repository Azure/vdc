########################################################################################################################
##
## ModuleInstanceDeployment.Tests.ps1
##
##      The purpose of this script is to perform the unit testing for the ModuleConfigurationDeployment Module using
##      Pester. The script will import the ModuleInstanceDeployment and any dependency modules to perform the tests.
##
########################################################################################################################

Describe  "Module Instance Deployment Orchestrator Unit Test Cases" {

    Context "Reference Function Resolution" {

        BeforeAll {
            $Env:KEYVAULT_MANAGEMENT_USER_ID = [Guid]::NewGuid();
            $Env:ADMIN_USER_PWD = "P@ssword2019";
            $Env:DOMAIN_ADMIN_USER_PWD = "P@ssword2019";
            $Env:VDC_SUBSCRIPTIONS = '{ "Toolkit": { "Comments": "Toolkit subscription and tenant information", "TenantId": "00000000-0000-0000-0000-000000000000", "SubscriptionId": "00000000-0000-0000-0000-000000000000", Location: "West US"}, "OnPremises": {"Comments": "Simulated On-Premises subscription and tenant information", "TenantId": "00000000-0000-0000-0000-000000000000", "SubscriptionId": "00000000-0000-0000-0000-000000000000", "Location": "West US 2"}, "SharedServices": {"Comments": "Shared services subscription and tenant information", "TenantId": "00000000-0000-0000-0000-000000000000", "SubscriptionId": "00000000-0000-0000-0000-000000000000", "Location": "West US 2"}, "ASE-SQL": {"Comments": "ASE/SQL Workload subscription and tenant information", "TenantId": "00000000-0000-0000-0000-000000000000", "SubscriptionId": "00000000-0000-0000-0000-000000000000", "Location": "West US"}}'
            $Env:VDC_TOOLKIT_SUBSCRIPTION = '{"Comments":"Toolkit subscription and tenant information","TenantId":"00000000-0000-0000-0000-000000000000","SubscriptionId":"00000000-0000-0000-0000-000000000000","Location":"West US"}'
           
        }

    }
}
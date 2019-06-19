########################################################################################################################
##
## DeploymentService.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the DeploymentService Module using Pester.
##          The script will import the DeploymentService Module and any dependency moduels to perform the tests.
##
########################################################################################################################

. ../../IntegrationService/Interface/IDeploymentService.ps1;
. ../../IntegrationService/Implementations/ARMDeploymentService.ps1;


$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe  "Deployment Service Unit Test Cases" {

    Context "Deploy Module Instance" {
        BeforeEach {
            $deploymentService = New-Object ARMDeploymentService;
            $subscriptionId = "4jfd84kk-e2cd-41df-b079-b99a20de7c6d";
            $subscriptionId = "dfkje890-e2cd-41df-b079-b99a20de7c6d";
            $resourceGroupName = "opsmgr";
            $template = Get-Content "../../../../modules/StorageAccounts/2.0/storage.account.deploy.json" -Raw;
            $parameters = Get-Content "../../../../modules/StorageAccounts/2.0/storage.account.parameters.json" -Raw;
            $parametersJson = ConvertFrom-Json $parameters -AsHashtable;

            # falsy
            <#if($parametersJson.parameters) {
                $parameters = ConvertTo-Json $parametersJson.parameters -Depth 50;
            }#>
            
        }
        It "Should invoke te Execute method in DeploymentService" {
            
           
            { $deploymentService.Execute($tenantId,
                    $subscriptionId,
                    $resourceGroupName,
                    $template,
                    $parameters
                ); } | Should Not Throw;
        }
    }
}
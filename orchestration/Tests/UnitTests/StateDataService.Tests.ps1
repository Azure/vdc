########################################################################################################################
##
## StateDataService.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the StateDataService Module using Pester.
##          The script will import the StateDataService Module and any dependency moduels to perform the tests.
##
########################################################################################################################

using Module './../../DataService/Interface/IModuleStateDataService.psd1';
using Module './../../DataService/Implementations/ModuleStateDataService.psd1';


$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe  "State Data Service Unit Test Cases" {

    Context "Save State" {
        BeforeEach {
            $stateDataService = New-Object StateDataService;
            $state = [PSCustomObject]@{
                'AuditId' = [Guid]::NewGuid()
                'DeploymentId' = [Guid]::NewGuid()
                'ResourceState' = 'mocked-state'
                'SubscriptionId' = [Guid]::NewGuid()
                'PolicyDefinitions' = 'mocked-policy-definitions'
                'RbacDefinitions' = 'mocked-rbac-definitions'
            }
        }
        It "Should save the resource state" {
            $stateId = $stateDataService.SaveResourceState($state);
            $retreivedState = $stateDataService.GetResourceStateById($stateId);
            $retreivedState.StateId | Should Be $stateId;
        }
    }

    Context "Get State" {
        BeforeEach {
            $stateDataService = New-Object StateDataService;
        }

        It "Should get the resource state by state id" {
            $stateId = [Guid]::NewGuid()
            $resourceState = $stateDataService.GetResourceStateById();
            $resourceState.StateId | Should Be $stateId;
        }

        It "Should get the resource states by audit id" {
            $auditId = [Guid]::NewGuid()
            $resourceStates = $stateDataService.GetResourceStatesById($auditId);
            $resourceStates.Count | Should BeGreaterThan 0;
        }

        It "Should get the resrouce state outputs by state id" {
            $stateId = [Guid]::NewGuid()
            $resourceStateOutputs = $stateDataService.GetResourceStateOutputsByStateId($stateId);
            $resourceStateOutputs.Count | Should BeGreaterThan 0;
        }

        It "Should get the resource state outputs by deployment id" {
            $deploymentId = [Guid]::NewGuid()
            $resourceStateOutputs = $stateDataService.GetResourceStateOutputsByDeploymentId($deploymentId);
            $resourceStateOutputs.Count | Should BeGreaterThan 0;
        }
    }
}
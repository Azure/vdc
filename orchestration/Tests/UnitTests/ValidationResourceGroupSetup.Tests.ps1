########################################################################################################################
##
## ValidationResourceGroup.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the ValidationResourceGroup Module using Pester.
##          The script will import the ValidationResourceGroup Module and any dependency moduels to perform the tests.
##
########################################################################################################################
$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent;
$scriptPath = Join-Path -Path $rootPath -ChildPath '..' -AdditionalChildPath @('..', 'OrchestrationService', 'ValidationResourceGroupSetup.ps1');
. $scriptPath;

Describe  "Validation Resource Group Unit Test Cases" {

    Context "Setup and Teardown Resource Group" {
        BeforeEach {
            $defaultResourceGroupName = "vdc-toolkit-validation-rg";
            $defaultResourceGroupLocation = "West US 2";
        }

        It "Should setup the validation resource group by passing name and location" {

            SetupResourceGroup `
                -ResourceGroupName $ResourceGroupName `
                -ResourceGroupLocation $ResourceGroupLocation;

            $resourceGroup = `
                Get-ValidationResourceGroup `
                    -ResourceGroupName $ResourceGroupName;

            $resourceGroup | Should Not Be $null;
        }

        It "Should teardown the validation resource group by passing name" {
            TearDownResourceGroup `
                -ResourceGroupName $ResourceGroupName;
            
            $resourceGroup = `
                Get-ValidationResourceGroup `
                    -ResourceGroupName $ResourceGroupName;

            $resourceGroup | Should Be $null;
        }
    }
}
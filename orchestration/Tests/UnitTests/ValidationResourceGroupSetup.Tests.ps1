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
        
    }
}
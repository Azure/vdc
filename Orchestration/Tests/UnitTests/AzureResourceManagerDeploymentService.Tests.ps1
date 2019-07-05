########################################################################################################################
##
## DeploymentService.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the DeploymentService Module using Pester.
##          The script will import the DeploymentService Module and any dependency moduels to perform the tests.
##
########################################################################################################################

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "IntegrationService", "Interface", "IDeploymentService.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "IntegrationService", "Implementations", "AzureResourceManagerDeploymentService.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

Describe  "Deployment Service Unit Test Cases" {

    Context "Deploy Module Instance" {
        
    }
}
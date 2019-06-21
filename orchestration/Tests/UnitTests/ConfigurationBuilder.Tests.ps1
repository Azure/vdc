########################################################################################################################
##
## ConfigurationBuilder.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the ConfigurationBuilder Module using Pester.
##          The script will import the ConfigurationBuilder Module and any dependency moduels to perform the tests.
##
########################################################################################################################

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$tokenReplacementSvcPath = Join-Path (Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath "..") -ChildPath 'TokenReplacementService') -ChildPath 'Interface') -ChildPath 'ITokenReplacementService.ps1'
$scriptBlock = ". $tokenReplacementSvcPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$tokenReplacementSvcPath = Join-Path (Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath "..") -ChildPath 'TokenReplacementService') -ChildPath 'Implementations') -ChildPath 'TokenReplacementService.ps1'
$scriptBlock = ". $tokenReplacementSvcPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$tokenReplacementSvcPath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath "..") -ChildPath 'OrchestrationService') -ChildPath 'ConfigurationBuilder.ps1'
$scriptBlock = ". $tokenReplacementSvcPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;


Describe  "Orchestration Instance Builder Unit Test Cases" {

    Context "Build Archetype Instance using nested file functions" {
        $ENV:FROMENVIRONMENTVARIABLE = "My value";
        $ENV:FROMANOTHERENVIRONMENTVARIABLE = "bar";
        It "Should build the archetype instance from definition file using absolute path" {
            $archetypeDefinitionFileAbsolutePath = Join-Path $rootPath -ChildPath ".." -AdditionalChildPath @("Tests", "Samples", "nested-file-functions", "paas", "archetype-definition.json");
            $ConfigurationBuilder = New-Object ConfigurationBuilder("shared-services", $archetypeDefinitionFileAbsolutePath);
            $archetypeInstance = $ConfigurationBuilder.BuildConfigurationInstance();
            $archetypeInstance.Subscriptions | Should BeOfType [object];
            $archetypeInstance.Subscriptions.Toolkit.nested.fromEnvironmentVariable| Should Be "My value";
            $archetypeInstance.Subscriptions.Toolkit.nested.concatEnvironmentVariables | Should Be "My value-bar";
            $archetypeInstance.ToolkitComponents | Should BeOfType [object];
            $archetypeInstance.ArchetypeParameters | Should BeOfType [object];
            $archetypeInstance.ArchetypeOrchestration | Should BeOfType [object];
        }
    }

    Context "Build Archetype Instance using environment variables" {
        $ENV:FROMENVIRONMENTVARIABLE = "My value";
        $ENV:FROMANOTHERENVIRONMENTVARIABLE = "bar";
        It "Should build the archetype instance from definition file using absolute path" {
            $archetypeDefinitionFileAbsolutePath = Join-Path $rootPath -ChildPath ".." -AdditionalChildPath @("Tests", "Samples", "shared-services", "archetype-definition.rel-path.json");
            $ConfigurationBuilder = New-Object ConfigurationBuilder("shared-services", $archetypeDefinitionFileAbsolutePath);
            $archetypeInstance = $ConfigurationBuilder.BuildConfigurationInstance();
            $archetypeInstance.Subscriptions | Should BeOfType [object];
        }
    }
}
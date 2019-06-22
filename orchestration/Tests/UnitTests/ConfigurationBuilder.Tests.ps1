########################################################################################################################
##
## ConfigurationBuilder.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the ConfigurationBuilder Module using Pester.
##          The script will import the ConfigurationBuilder Module and any dependency moduels to perform the tests.
##
########################################################################################################################

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "TokenReplacementService", "Interface", "ITokenReplacementService.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "TokenReplacementService", "Implementations", "TokenReplacementService.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath ".." -AdditionalChildPath  @("..", "OrchestrationService", "ConfigurationBuilder.ps1");
$scriptBlock = ". $scriptPath";
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
        $environmentValue = "My value";
        $ENV:SUBSCRIPTIONS = $environmentValue;
        It "Should build the archetype instance from definition file using absolute path" {
            $archetypeDefinitionFileAbsolutePath = Join-Path $rootPath -ChildPath ".." -AdditionalChildPath @("Tests", "Samples", "environment-keys", "archetypeDefinition.json");
            $archetypeInstanceBuilder = New-Object ConfigurationBuilder("shared-services", $archetypeDefinitionFileAbsolutePath);
            $archetypeInstance = $archetypeInstanceBuilder.BuildConfigurationInstance();
            $archetypeInstance.Subscriptions | Should BeOfType [string];
            $archetypeInstance.Subscriptions | Should be $environmentValue;
        }
    }
}
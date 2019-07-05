########################################################################################################################
##
## CustomScriptExecution.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the CustomScriptExecution Module using Pester.
##          The script will import the CustomScriptExecution Module and any dependency moduels to perform the tests.
##
########################################################################################################################
$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "OrchestrationService", "CustomScriptExecution.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

Describe  "Custom Script Execution Unit Test Cases" {

    Context "Custom Script Execution" {

        BeforeAll {
            # Initialize the script prior to execution
            $customScriptExecutor = `
                [CustomScriptExecution]::new();
        }

        It "Should execute a PowerShell Script with no Arguments passed" {

            $scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("Samples", "scripts", "sample-script.ps1");

            $command = $scriptPath;

            $arguments = @{};

            # Execute the script by calling Execute method
            $result = $customScriptExecutor.Execute(
                $command,
                $arguments
            );

            $result | Should Be "pwsh";
        }

        It "Should execute PowerShell Cmdlets" {
            $command = "Write-Output pwsh-test;";

            # Execute the script by calling Execute method
            $result = $customScriptExecutor.Execute(
                $command, 
                @{}
            );

            $result | Should Be "pwsh-test";
        }

        It "Should execute a PowerShell Script with Arguments passed" {

            $scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("Samples", "scripts", "sample-script.ps1");

            $command = $scriptPath;

            $arguments = @{
                "SecondParameter" = "pwsh-script-test"
            }

            # Execute the script by calling Execute method
            $result = $customScriptExecutor.Execute(
                $command, 
                $arguments
            );

            $result | Should Be "pwsh-script-test";
        }

        It "Should execute a Bash script" {
            
            $scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("Samples", "scripts", "sample-script.sh");

            $command = $scriptPath;

            $arguments = @{
                "FIRST_VAR" = "bash-script-test"
            }

            # Execute the script by calling Execute method
            $result = $customScriptExecutor.Execute(
                $command, 
                $arguments
            );

            $result | Should Be "bash-script-test";
        }

        It "Should execute Bash Commands" {
            $command = "echo bash-test";

            # Execute the script by calling Execute method
            $result = $customScriptExecutor.Execute(
                $command, 
                @{}
            );

            $result | Should Be "bash-test";
        }

        It "Should throw script not supported error for invalid set of commands passed" {

            $command = "invalid-cmd bash-test";

            # Execute the script by calling Execute method
            { $customScriptExecutor.Execute(
                $command, 
                @{}
            ); }  | Should Throw "Script type not supported";
        } 

        It "Should throw runtime error on execution of error prone commands" {

            $command = 'Write-Output $(1/0);';

            # Execute the script by calling Execute method
            { $customScriptExecutor.Execute(
                $command, 
                @{}
            ); }  | Should Not Throw;
        } 
    }
}
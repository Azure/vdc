########################################################################################################################
##
## ModuleInstanceDeployment.Tests.ps1
##
##      The purpose of this script is to perform the unit testing for the ModuleInstanceDeployment Module using
##      Pester. The script will import the ModuleInstanceDeployment and any dependency modules to perform the tests.
##
########################################################################################################################
Import-Module './../../OrchestrationService/ModuleInstanceDeployment.ps1';

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host $ScriptPath;
Describe  "Module Instance Deployment Orchestrator Unit Test Cases" {

    Context "Policy Deployment" {
        BeforeEach {
            $defaultWorkingDirectory = "$ScriptPath/../../../../";
            $ArchetypeDefinitionPath = "$ScriptPath/../../../../archetypes/shared-services/2.0/archetypeDefinition.json";
            $archetypeInstanceJson = `
                Build-ConfigurationUsingFile `
                    -ArchetypeDefinitionPath $ArchetypeDefinitionPath;
        }

        It "should get the contents of the Polcy assignment template" {

            $moduleConfiguration =$archetypeInstanceJson.ArchetypeOrchestration.ModuleConfigurations[0];
            $policyTemplate = `
                Get-PolicyDeploymentTemplateFileContents `
                    -DeploymentConfiguration $moduleConfiguration.Policies `
                    -ModuleDefinitionsRootPath "$ScriptPath/../../../../";
            $policyTemplate | Should BeOfType [System.Object];
        }

        It "Should get the contents of the Policy assignment parameters" {
            # TODO: Will Policy Template have parameters? If so, will the executePolicyAssignment return two return values
            $moduleConfiguration =$archetypeInstanceJson.ArchetypeOrchestration.ModuleConfigurations[0];
            $policyParameters = `
                Get-PolicyDeploymentParametersFileContents `
                    -DeploymentConfiguration $moduleConfiguration.Policies `
                    -ModuleDefinitionsRootPath $archetypeInstanceJson.ArchetypeOrchestration.ModuleDefinitionsRootPath;
            $policyParameters | Should BeOfType [System.Object];
        }

    }

    Context "Reference Function Resolution" {
        BeforeEach {
            $defaultWorkingDirectory = "$ScriptPath/../../../../";
            $ArchetypeDefinitionPath = "$ScriptPath/../../../../archetypes/shared-services/2.0/archetypeDefinition.json";

            

            $archetypeInstanceJson = `
                Build-ConfigurationUsingFile  `
                    -ArchetypeDefinitionPath $ArchetypeDefinitionPath;
            $cacheRepository = `
                [AzureDevOpsCacheRepository]::new();
            $cacheDataService = `
                    [CacheDataService]::new($cacheRepository);
        }

        It "Should replace single reference function in a string with cached value" {
            $referenceFunctionString ="reference(archetypeInstanceA.moduleInstanceA.outputA)-in-output";

            $outputs = @{
                "outputA" =  @{
                    "Value" = "DemoA"
                };
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $output = `
                Get-OutputReferenceValue `
                    -ParameterValue $referenceFunctionString `
                    -ArchetypeInstanceName "ArchetypeA";

            $output.result | Should Be "DemoA-in-output";
        }

        It "Should replace more than one reference functions in a string with cached value" {
            $referenceFunctionString ="reference(archetypeInstanceA.moduleInstanceA.outputA)-in-reference(archetypeInstanceA.moduleInstanceA.outputB)";

            $outputs = @{
                "outputA" =  @{
                    "Value" = "DemoA"
                };
                "outputB" = @{
                    "Value" = "DemoB"
                };
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $output = `
                Get-OutputReferenceValue `
                    -ParameterValue $referenceFunctionString `
                    -ArchetypeInstanceName "ArchetypeA";

            $output.result | Should Be "DemoA-in-DemoB";
        }

        It "Should replace more than one reference functions in a string with cached value" {
            $referenceFunctionString ="reference(archetypeInstanceA.moduleInstanceA.outputA)";

            $outputs = @{
                "outputA" =  @{
                    "Value" = @{
                        "parameterA" = "valueForParameterA";
                        "parameterB" = "valueForParameterB";
                    }
                }
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $output = `
                Get-OutputReferenceValue `
                    -ParameterValue $referenceFunctionString `
                    -ArchetypeInstanceName "ArchetypeA";

            $output.result.Keys `
                | Sort-Object `
                | Should Be @( 'parameterA', 'parameterB')
        }

        It "Should process one parameter and return value by resolving reference functions" {

            $parametersWithReferenceFunctions = @{
                "parameterA" = @{
                    "Value" = "reference(archetypeInstanceA.moduleInstanceA.outputA)"
                };
                "parameterB" = @{
                    "Value" = "no-reference-functions-here"
                };
            }

            $outputs = @{
                "outputA" =  @{
                    "Value" = "DemoA"
                };
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $resolvedParameters = `
                Resolve-OutputReferencesInOverrideParameters `
                    -OverrideParameters $parametersWithReferenceFunctions `
                    -ArchetypeInstanceName "Shared-Services";

            $resolvedParameters | Should BeOfType [object];
            $resolvedParameters.parameterA.Value | Should Be $outputs.outputA.Value;

        }

        It "Should process one nested parameter and return value by resolving reference functions" {

            $parametersWithReferenceFunctions = @{
                "parameterA" = @{
                    "Value" =  @{
                        "VirtualMachineName" = "reference(archetypeInstanceA.moduleInstanceA.outputA)"
                    }
                };
                "parameterB" = @{
                    "Value" = "no-reference-functions-here"
                };
            }

            $outputs = @{
                "outputA" =  @{
                    "Value" = "DemoA"
                };
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $resolvedParameters = `
                Resolve-OutputReferencesInOverrideParameters `
                    -OverrideParameters $parametersWithReferenceFunctions `
                    -ArchetypeInstanceName "Shared-Services";

            $resolvedParameters | Should BeOfType [object];
            $resolvedParameters.parameterA.Value.VirtualMachineName | Should Be $outputs.outputA.Value;

        }

        It "Should process one nested parameter with more than one reference functions and return value by resolving reference functions" {

            $parametersWithReferenceFunctions = @{
                "parameterA" = @{
                    "Value" =  @{
                        "VirtualMachineName" = "reference(archetypeInstanceA.moduleInstanceA.outputA)-in-reference(archetypeInstanceA.moduleInstanceA.outputB)"
                    }
                };
                "parameterB" = @{
                    "Value" = "no-reference-functions-here"
                };
            }

            $outputs = @{
                "outputA" =  @{
                    "Value" = "DemoA"
                };
                "outputB" =  @{
                    "Value" = "DemoB"
                };
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $resolvedParameters = `
                Resolve-OutputReferencesInOverrideParameters `
                    -OverrideParameters $parametersWithReferenceFunctions `
                    -ArchetypeInstanceName "Shared-Services";

            $resolvedParameters | Should BeOfType [object];
            $resolvedParameters.parameterA.Value.VirtualMachineName `
                | Should Be `
                    ("{0}-in-{1}" -F $outputs.outputA.Value, $outputs.outputB.Value);

        }

        It "Should process array with one reference functions and return value by resolving reference functions" {

            $parametersWithReferenceFunctions = @{
                "parameterA" = @{
                    "Value" = @(
                        "reference(archetypeInstanceA.moduleInstanceA.outputA)"
                    )
                };
                "parameterB" = @{
                    "Value" = "no-reference-functions-here"
                };
            }

            $outputs = @{
                "outputA" =  @{
                    "Value" = "DemoA"
                };
                "outputB" =  @{
                    "Value" = "DemoB"
                };
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $resolvedParameters = `
                Resolve-OutputReferencesInOverrideParameters `
                    -OverrideParameters $parametersWithReferenceFunctions `
                    -ArchetypeInstanceName "Shared-Services";

            $resolvedParameters | Should BeOfType [object];
            $resolvedParameters.parameterA.Value[0] `
                | Should Be $outputs.outputA.Value;

        }

        It "Should process array with more than one reference functions and return value by resolving reference functions" {

            $parametersWithReferenceFunctions = @{
                "parameterA" = @{
                    "Value" = @(
                        "reference(archetypeInstanceA.moduleInstanceA.outputA)",
                        "reference(archetypeInstanceA.moduleInstanceA.outputB)"
                    )
                };
                "parameterB" = @{
                    "Value" = "no-reference-functions-here"
                };
            }

            $outputs = @{
                "outputA" =  @{
                    "Value" = "DemoA"
                };
                "outputB" =  @{
                    "Value" = "DemoB"
                };
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $resolvedParameters = `
                Resolve-OutputReferencesInOverrideParameters `
                    -OverrideParameters $parametersWithReferenceFunctions `
                    -ArchetypeInstanceName "Shared-Services";

            $resolvedParameters | Should BeOfType [object];
            $resolvedParameters.parameterA.Value `
                | Sort-Object `
                | Should Be @($outputs.outputA.Value, $outputs.outputB.Value);

        }

        It "Should process one nested parameter with more than one reference functions and return value by resolving reference functions" {

            $parametersWithReferenceFunctions = @{
                "parameterA" = @{
                    "Value" =  @{
                        "VirtualMachines" = @{ 
                            "vm1" = "reference(archetypeInstanceA.moduleInstanceA.outputA)-in-reference(archetypeInstanceA.moduleInstanceA.outputB)"
                        }
                        "VirtualNetwork" = @{
                            "Name" = "vNet"
                        }
                    }
                };
                "parameterB" = @{
                    "Value" = "no-reference-functions-here"
                };
            }

            $outputs = @{
                "outputA" =  @{
                    "Value" = "DemoA"
                };
                "outputB" =  @{
                    "Value" = "DemoB"
                };
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $resolvedParameters = `
                Resolve-OutputReferencesInOverrideParameters `
                    -OverrideParameters $parametersWithReferenceFunctions `
                    -ArchetypeInstanceName "Shared-Services";

            $resolvedParameters | Should BeOfType [object];
            $resolvedParameters.parameterA.Value.VirtualMachines.vm1 `
                | Should Be `
                    ("{0}-in-{1}" -F $outputs.outputA.Value, $outputs.outputB.Value);

        }

        It "Should process multiple nested parameter with more than one reference functions and return value by resolving reference functions" {

            $parametersWithReferenceFunctions = @{
                "parameterA" = @{
                    "Value" =  @{
                        "VirtualMachines" = @{ 
                            "vm1" = "reference(archetypeInstanceA.moduleInstanceA.outputA)-in-reference(archetypeInstanceA.moduleInstanceA.outputB)"
                            
                        }
                        "VirtualNetwork" = @{
                            "Name" = "vNet"
                        }
                    }
                };
                "parameterB" = @{
                    "Value" = "reference(archetypeInstanceA.moduleInstanceA.outputC)"
                };
                "parameterC" = @{
                    "Value" = "reference(archetypeInstanceA.moduleInstanceA.outputD)"
                };
            }

            $outputs = @{
                "outputA" =  @{
                    "Value" = "DemoA"
                };
                "outputB" =  @{
                    "Value" = "DemoB"
                };
                "outputC" =  @{
                    "Value" = $true
                };
                "outputD" =  @{
                    "Value" = 12
                };
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $resolvedParameters = `
                Resolve-OutputReferencesInOverrideParameters `
                    -OverrideParameters $parametersWithReferenceFunctions `
                    -ArchetypeInstanceName "Shared-Services";

            $resolvedParameters | Should BeOfType [object];
            $resolvedParameters.parameterA.Value.VirtualMachines.vm1 `
                | Should Be `
                    ("{0}-in-{1}" -F $outputs.outputA.Value, $outputs.outputB.Value);
            $resolvedParameters.parameterB.Value `
                | Should Be $true;
            $resolvedParameters.parameterC.Value `
                | Should Be 12;

        }

        It "Should process multiple nested parameter with more than one reference functions and return value by resolving reference functions" {

            $parametersWithReferenceFunctions = @{
                "parameterA" = @{
                    "Value" =  @{
                        "VirtualMachines" = @{ 
                            "vm1" = "reference(archetypeInstanceA.moduleInstanceA.outputA)-in-reference(archetypeInstanceA.moduleInstanceA.outputB)"
                            
                        }
                        "VirtualNetwork" = @{
                            "Name" = "vNet"
                        }
                    }
                };
                "parameterB" = @{
                    "Value" = "reference(archetypeInstanceA.moduleInstanceA.outputC)"
                };
                "parameterC" = @{
                    "Value" = "reference(archetypeInstanceA.moduleInstanceA.outputD)"
                };
            }

            $outputs = @{
                "outputA" =  @{
                    "Value" = "DemoA"
                };
                "outputB" =  @{
                    "Value" = "Demo B"
                };
                "outputC" =  @{
                    "Value" = @{
                        "nestedOutputC1" = "ValueForC1"
                        "nestedOutputC2" = @{
                            "nestedOutputC21" = "ValueForC21"
                        }
                    }
                };
                "outputD" =  @{
                    "Value" = @( 'a', 'b', 'c', 'd' )
                };
            }

            $Env:VDC_CACHE_ARCHETYPEINSTANCEA_MODULEINSTANCEA = `
                ConvertTo-Json `
                    -InputObject $outputs `
                    -Depth 50 `
                    -Compress;

            $resolvedParameters = `
                Resolve-OutputReferencesInOverrideParameters `
                    -OverrideParameters $parametersWithReferenceFunctions `
                    -ArchetypeInstanceName "Shared-Services";

            $resolvedParameters | Should BeOfType [object];
            $resolvedParameters.parameterA.Value.VirtualMachines.vm1 `
                | Should Be `
                    ("{0}-in-{1}" -F $outputs.outputA.Value, $outputs.outputB.Value);
            $resolvedParameters.parameterB.Value.nestedOutputC1 `
                | Should Be $outputs.outputC.Value.nestedOutputC1;   
            $resolvedParameters.parameterC.Value `
                | Should Be $outputs.OutputD.Value;

        }
    }

}
########################################################################################################################
##
## TokenReplacementService.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the TokenReplacementService Module using Pester.
##          The script will import the TokenReplacementService Module and any dependency moduels to perform the tests.
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

$sharedServicesArcheJsonPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "..", "archetypes", "shared-services", "archetype.test.json");
$onpremArcheJsonPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "..", "archetypes", "on-premises", "archetype.test.json");
$iaasArcheJsonPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "..", "archetypes", "ntier-iaas", "archetype.test.json");

Describe  "Token Replacement Service Unit Test Cases" {

    Context "Token Replacement" {
        BeforeEach {
            $tokenReplacementService = New-Object TokenReplacementService;
        }
        It "Should replace properties from child object and no environment keys" {
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4' = [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44' = [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_intValue}'
                                                            }
                                                    } } 
            $tokenValues = [PSCustomObject]@{ "shared-services"=  
                                                    [PSCustomObject]@{    
                                                        "par441" = [PSCustomObject]@{"boolValue" = $true}
                                                        "par442_intValue" = 1
                                                } }

            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par441 | Should Be $True;
            $result.par4.par44.par442 | Should Be 1;
        }

        It "Should replace properties from child object evaluate next ip function operands and no environment keys" {
            
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4' = [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44' = [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_strValue}'
                                                            }
                                                    } } 
            $tokenValues = [PSCustomObject]@{ "shared-services"=  
                                                    [PSCustomObject]@{    
                                                        "par441" = [PSCustomObject]@{"boolValue" = $true}
                                                        "par442_strValue" = '192.168.0.0'
                                                } } 

            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par441 | Should Be $True;
            $result.par4.par44.par442 | Should Be '192.168.0.0';
        }

        It "Should replace property from parent object with string value from array and no environment keys" {
            
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4' = [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par45' = '${shared-services.par45_strFromArrayValue[0]}'
                                                    } } 
            $tokenValues = [PSCustomObject]@{ "shared-services"=  
                                                    [PSCustomObject]@{    
                                                        'par441' = [PSCustomObject]@{'boolValue' = $true}
                                                        'par442_strValue' = '192.168.0.0'
                                                        'par45_strFromArrayValue' = @( 'a', 'b' )
                                                } } 

            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par45 | Should Be 'a';
        }

        It "Should replace array index with dictionary and no environment keys" {
            
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4' = [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par46' = @( '${shared-services.par46[0].dictValue}', 
                                                                        [PSCustomObject]@{  'a' = 1
                                                                                            'b' = 2
                                                            })
                                                    } } 
            $tokenValues = [PSCustomObject]@{ "shared-services"=  
                                                    [PSCustomObject]@{    
                                                        'par46' = @(
                                                            [PSCustomObject]@{ 
                                                                'dictValue'= [PSCustomObject]@{
                                                                    'a'=1
                                                                    'b'=$True
                                                                    'c'='text'
                                                                }
                                                            }
                                                            [PSCustomObject]@{
                                                                'newDictValue'= [PSCustomObject]@{
                                                                    'd'=2
                                                                    'e'=$False
                                                                    'f'='new text'
                                                                }
                                                            }
                                                        )
                                                } } 
            $refResult = [PSCustomObject]@{ 'a'= 1 
                                            'b'=$True 
                                            'c'='text' }
            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par46[0].a | Should Be 1;
            $result.par4.par46[0].b | Should Be $True;
            $result.par4.par46[0].c | Should Be 'text';
        }

        It "Should replace property with array and no environment keys" {
            
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4'= [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par48' = '${shared-services.par48_arrayValue}'
                                                    }
                                                    'par5'= 'some value'
                                                 } 
            $tokenValues = [PSCustomObject]@{ "shared-services"=  
                                                    [PSCustomObject]@{    
                                                        'par48_arrayValue'= @('a', 'b', 'c')
                                                        'par491_intValue'= 10
                                                        'par6_strValue'= 'value'
                                                } } 
            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par48 | Should Be @('a', 'b', 'c');
        }

        It "Should replace all tokens and no environment keys" {
            
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4'= [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44'= [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_intValue}'
                                                            }
                                                            'par45'= '${shared-services.par45_strFromArrayValue[0]}'
                                                            'par46'= @(
                                                                '${shared-services.par46[0].dictValue}',
                                                                [PSCustomObject]@{
                                                                    'a'= 1
                                                                    'b'= 2
                                                                }
                                                            )
                                                            'par47'= '${shared-services.par47[1].arrayValue}'
                                                            'par48'= '${shared-services.par48_arrayValue}'
                                                            'par49'= [PSCustomObject]@{
                                                                'par491'= '${shared-services.par491_intValue}'
                                                            }

                                                    }
                                                    'par5'= 'some value'
                                                 } 
            $tokenValues = [PSCustomObject]@{   'shared-services'= [PSCustomObject]@{
                                                'par441'= [PSCustomObject]@{
                                                    'boolValue'= $True
                                                }
                                                'par442_intValue'= 1
                                                'par45_strFromArrayValue'= @(
                                                    'a',
                                                    'b'
                                                )
                                                'par46'= @(
                                                    [PSCustomObject]@{
                                                        'dictValue'= [PSCustomObject]@{
                                                            'a'= 1
                                                            'b'= $True
                                                            'c'= 'text'
                                                        }
                                                    },
                                                    [PSCustomObject]@{
                                                        'newDictValue'= [PSCustomObject]@{
                                                            'd'= 2
                                                            'e'= $False
                                                            'f'= 'new text'
                                                        }
                                                    }
                                                )
                                                'par47'= @(
                                                    [PSCustomObject]@{
                                                        'newarrayValue'= @(
                                                            [PSCustomObject]@{
                                                                'a'= 1
                                                                'b'= $True
                                                                'c'= 'text'
                                                            }
                                                        )
                                                    },
                                                    [PSCustomObject]@{
                                                        'arrayValue'= @(
                                                            [PSCustomObject]@{
                                                                'd'= 2
                                                                'e'= $False
                                                                'f'= 'new text'
                                                            }
                                                        )
                                                    }
                                                )
                                                'par48_arrayValue'= @(
                                                    'a',
                                                    'b',
                                                    'c'
                                                )
                                                'par491_intValue'= 10
                                                'par6_strValue'= 'value'
                                            }
                                        }
                                         
            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par441 | Should Be $True;
            $result.par4.par44.par442 | Should Be 1;
            $result.par4.par45 | Should BeOfType string;
            $result.par4.par46 | Should BeOfType object;
            $result.par4.par47 | Should BeOfType object;
            $result.par4.par48 | Should BeOfType object;
            $result.par4.par49.par491 | Should BeOfType int;
        }

        It "Should replace all tokens with root string token value and no environment keys" {
            
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4'= [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44'= [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_intValue}'
                                                            }
                                                            'par45'= '${shared-services.par45_strFromArrayValue[0]}'
                                                            'par46'= @(
                                                                '${shared-services.par46[0].dictValue}',
                                                                [PSCustomObject]@{
                                                                    'a'= 1
                                                                    'b'= 2
                                                                }
                                                            )
                                                            'par47'= '${shared-services.par47[1].arrayValue}'
                                                            'par48'= '${shared-services.par48_arrayValue}'
                                                            'par49'= [PSCustomObject]@{
                                                                'par491'= '${shared-services.par491_intValue}'
                                                            }

                                                    }
                                                    'par5'= 'some value'
                                                    'par6'= '${shared-services.par6_strValue}'
                                                 } 
            $tokenValues = [PSCustomObject]@{   'shared-services'= [PSCustomObject]@{
                                                'par441'= [PSCustomObject]@{
                                                    'boolValue'= $True
                                                }
                                                'par442_intValue'= 1
                                                'par45_strFromArrayValue'= @(
                                                    'a',
                                                    'b'
                                                )
                                                'par46'= @(
                                                    [PSCustomObject]@{
                                                        'dictValue'= [PSCustomObject]@{
                                                            'a'= 1
                                                            'b'= $True
                                                            'c'= 'text'
                                                        }
                                                    },
                                                    [PSCustomObject]@{
                                                        'newDictValue'= [PSCustomObject]@{
                                                            'd'= 2
                                                            'e'= $False
                                                            'f'= 'new text'
                                                        }
                                                    }
                                                )
                                                'par47'= @(
                                                    [PSCustomObject]@{
                                                        'newarrayValue'= @(
                                                            [PSCustomObject]@{
                                                                'a'= 1
                                                                'b'= $True
                                                                'c'= 'text'
                                                            }
                                                        )
                                                    },
                                                    [PSCustomObject]@{
                                                        'arrayValue'= @(
                                                            [PSCustomObject]@{
                                                                'd'= 2
                                                                'e'= $False
                                                                'f'= 'new text'
                                                            }
                                                        )
                                                    }
                                                )
                                                'par48_arrayValue'= @(
                                                    'a',
                                                    'b',
                                                    'c'
                                                )
                                                'par491_intValue'= 10
                                                'par6_strValue'= 'value'
                                            }
                                        }
            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par441 | Should BeOfType bool;
            $result.par4.par44.par442 | Should BeOfType int;
            $result.par4.par45 | Should BeOfType string;
            $result.par4.par46 | Should BeOfType object;
            $result.par4.par47 | Should BeOfType object;
            $result.par4.par48 | Should BeOfType object;
            $result.par4.par49.par491 | Should BeOfType int;
            $result.par6 | Should BeOfType string;
        }

        It "Should replace all tokens with root array token value and no environment keys" {
            
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4'= [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44'= [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_intValue}'
                                                            }
                                                            'par45'= '${shared-services.par45_strFromArrayValue[0]}'
                                                            'par46'= @(
                                                                '${shared-services.par46[0].dictValue}',
                                                                [PSCustomObject]@{
                                                                    'a'= 1
                                                                    'b'= 2
                                                                }
                                                            )
                                                            'par47'= '${shared-services.par47[1].arrayValue}'
                                                            'par48'= '${shared-services.par48_arrayValue}'
                                                            'par49'= [PSCustomObject]@{
                                                                'par491'= '${shared-services.par491_intValue}'
                                                            }

                                                    }
                                                    'par5'= 'some value'
                                                    'par6'= '${shared-services.par6_arrayValue}'
                                                 } 
            $tokenValues = [PSCustomObject]@{   'shared-services'= [PSCustomObject]@{
                                                    'par441'= [PSCustomObject]@{
                                                        'boolValue'= $True
                                                    }
                                                    'par442_intValue'= 1
                                                    'par45_strFromArrayValue'= @(
                                                        'a',
                                                        'b'
                                                    )
                                                    'par46'= @(
                                                        [PSCustomObject]@{
                                                            'dictValue'= [PSCustomObject]@{
                                                                'a'= 1
                                                                'b'= $True
                                                                'c'= 'text'
                                                            }
                                                        },
                                                        [PSCustomObject]@{
                                                            'newDictValue'= [PSCustomObject]@{
                                                                'd'= 2
                                                                'e'= $False
                                                                'f'= 'new text'
                                                            }
                                                        }
                                                    )
                                                    'par47'= @(
                                                        [PSCustomObject]@{
                                                            'newarrayValue'= @(
                                                                [PSCustomObject]@{
                                                                    'a'= 1
                                                                    'b'= $True
                                                                    'c'= 'text'
                                                                }
                                                            )
                                                        },
                                                        [PSCustomObject]@{
                                                            'arrayValue'= @(
                                                                [PSCustomObject]@{
                                                                    'd'= 2
                                                                    'e'= $False
                                                                    'f'= 'new text'
                                                                }
                                                            )
                                                        }
                                                    )
                                                    'par48_arrayValue'= @(
                                                        'a',
                                                        'b',
                                                        'c'
                                                    )
                                                    'par491_intValue'= 10
                                                    'par6_arrayValue'= [array]@(
                                                        1,
                                                        2,
                                                        3
                                                    )
                                                }
                                            }
                                         
            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par441 | Should BeOfType bool;
            $result.par4.par44.par442 | Should BeOfType int;
            $result.par4.par45 | Should BeOfType string;
            $result.par4.par46 | Should BeOfType object;
            $result.par4.par47 | Should BeOfType object;
            $result.par4.par48 | Should BeOfType object;
            $result.par4.par49.par491 | Should BeOfType int;
            $result.par6[0] | Should Be 1;
        }

        It "Should replace all tokens with an environment key that contains multiple properties" {
            
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4'= [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44'= [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_intValue}'
                                                            }
                                                            'par45'= '${shared-services.par45_strFromArrayValue[0]}'
                                                            'par46'= @(
                                                                '${shared-services.par46[0].dictValue}',
                                                                [PSCustomObject]@{
                                                                    'a'= 1
                                                                    'b'= 2
                                                                }
                                                            )
                                                            'par47'= '${shared-services.par47[1].arrayValue}'
                                                            'par48'= '${shared-services.par48_arrayValue}'
                                                            'par49'= [PSCustomObject]@{
                                                                'par491'= '${shared-services.par491_intValue}'
                                                            }

                                                    }
                                                    'par5'= 'some value'
                                                    'par6'= 'main-module/v1.0/${ENV:ENVIRONMENT-TYPE.prop1.prop2}'
                                                    'par7'= '${shared-services.par7_strValue}'
                                                    'par8'= @(
                                                        1,
                                                        2,
                                                        '${shared-services.par8_intValue}'
                                                    )
                                                    'par9'= @(
                                                        [PSCustomObject]@{
                                                            'par91'= 'value91'
                                                            'par92'= 'value92'
                                                            'par93'= '${shared-services.par93.arrayValue}'
                                                        }
                                                    )
                                                 } 
            $tokenValues = [PSCustomObject]@{   'shared-services'= [PSCustomObject]@{
                                                    'prop1'= [PSCustomObject]@{
                                                        'prop2' = 'hello'
                                                    }
                                                    'par441'= [PSCustomObject]@{
                                                        'boolValue'= $True
                                                    }
                                                    'par442_intValue'= 1
                                                    'par45_strFromArrayValue'= @(
                                                        'a',
                                                        'b'
                                                    )
                                                    'par46'= @(
                                                        [PSCustomObject]@{
                                                            'dictValue'= [PSCustomObject]@{
                                                                'a'= 1
                                                                'b'= $True
                                                                'c'= 'text'
                                                            }
                                                        },
                                                        [PSCustomObject]@{
                                                            'newDictValue'= [PSCustomObject]@{
                                                                'd'= 2
                                                                'e'= $False
                                                                'f'= 'new text'
                                                            }
                                                        }
                                                    )
                                                    'par47'= @(
                                                        [PSCustomObject]@{
                                                            'newarrayValue'= @(
                                                                [PSCustomObject]@{
                                                                    'a'= 1
                                                                    'b'= $True
                                                                    'c'= 'text'
                                                                }
                                                            )
                                                        },
                                                        [PSCustomObject]@{
                                                            'arrayValue'= @(
                                                                [PSCustomObject]@{
                                                                    'd'= 2
                                                                    'e'= $False
                                                                    'f'= 'new text'
                                                                }
                                                            )
                                                        }
                                                    )
                                                    'par48_arrayValue'= @(
                                                        'a',
                                                        'b',
                                                        'c'
                                                    )
                                                    'par491_intValue'= 10
                                                    'par7_strValue'= 'hello world'
                                                    'par8_intValue'= 20
                                                    'par93'= [PSCustomObject]@{
                                                        'arrayValue'= @(
                                                            'a',
                                                            'b',
                                                            'c'
                                                        )
                                                    }
                                                }
                                            }
                                         
            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par441 | Should BeOfType bool;
            $result.par4.par44.par442 | Should BeOfType int;
            $result.par4.par45 | Should BeOfType string;
            $result.par4.par46 | Should BeOfType object;
            $result.par4.par47 | Should BeOfType object;
            $result.par4.par48 | Should BeOfType object;
            $result.par4.par49.par491 | Should BeOfType int;
            $result.par6 | Should Be 'main-module/v1.0/hello';
            $result.par7 | Should Be 'hello world';
            $result.par8[2] | Should Be 20;
        }

        It "Should replace all tokens with environment keys" {
            
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4'= [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44'= [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_intValue}'
                                                            }
                                                            'par45'= '${shared-services.par45_strFromArrayValue[0]}'
                                                            'par46'= @(
                                                                '${shared-services.par46[0].dictValue}',
                                                                [PSCustomObject]@{
                                                                    'a'= 1
                                                                    'b'= 2
                                                                }
                                                            )
                                                            'par47'= '${shared-services.par47[1].arrayValue}'
                                                            'par48'= '${shared-services.par48_arrayValue}'
                                                            'par49'= [PSCustomObject]@{
                                                                'par491'= '${shared-services.par491_intValue}'
                                                            }

                                                    }
                                                    'par5'= 'some value'
                                                    # TODO: Check #1 - is this is a valid case?
                                                    # Python toolkit expects shared-services but Powershell sends back an object
                                                    'par6'= 'main-module/v1.0/${ENV:ENVIRONMENT-TYPE}'
                                                    # TODO: Check #2 - is this is a valid case?
                                                    # Python toolkit expects shared-services but Powershell sends back an object
                                                    'par61'= '${shared-services.par7_strValue}/v1.0/${ENV:ENVIRONMENT-TYPE}'
                                                    'par7'= '${shared-services.par7_strValue}'
                                                    'par8'= @(
                                                        1,
                                                        2,
                                                        '${shared-services.par8_intValue}'
                                                    )
                                                    'par9'= @(
                                                        [PSCustomObject]@{
                                                            'par91'= 'value91'
                                                            'par92'= 'value92'
                                                            'par93'= '${shared-services.par93.arrayValue}'
                                                        }
                                                    )
                                                 } 
            $tokenValues = [PSCustomObject]@{   'shared-services'= [PSCustomObject]@{
                                                    'prop1'= [PSCustomObject]@{
                                                        'prop2' = 'hello'
                                                    }
                                                    'par441'= [PSCustomObject]@{
                                                        'boolValue'= $True
                                                    }
                                                    'par442_intValue'= 1
                                                    'par45_strFromArrayValue'= @(
                                                        'a',
                                                        'b'
                                                    )
                                                    'par46'= @(
                                                        [PSCustomObject]@{
                                                            'dictValue'= [PSCustomObject]@{
                                                                'a'= 1
                                                                'b'= $True
                                                                'c'= 'text'
                                                            }
                                                        },
                                                        [PSCustomObject]@{
                                                            'newDictValue'= [PSCustomObject]@{
                                                                'd'= 2
                                                                'e'= $False
                                                                'f'= 'new text'
                                                            }
                                                        }
                                                    )
                                                    'par47'= @(
                                                        [PSCustomObject]@{
                                                            'newarrayValue'= @(
                                                                [PSCustomObject]@{
                                                                    'a'= 1
                                                                    'b'= $True
                                                                    'c'= 'text'
                                                                }
                                                            )
                                                        },
                                                        [PSCustomObject]@{
                                                            'arrayValue'= @(
                                                                [PSCustomObject]@{
                                                                    'd'= 2
                                                                    'e'= $False
                                                                    'f'= 'new text'
                                                                }
                                                            )
                                                        }
                                                    )
                                                    'par48_arrayValue'= @(
                                                        'a',
                                                        'b',
                                                        'c'
                                                    )
                                                    'par491_intValue'= 10
                                                    'par7_strValue'= 'hello world'
                                                    'par8_intValue'= 20
                                                    'par93'= [PSCustomObject]@{
                                                        'arrayValue'= @(
                                                            'a',
                                                            'b',
                                                            'c'
                                                        )
                                                    }
                                                }
                                            }
                                         
            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par441 | Should BeOfType bool;
            $result.par4.par44.par442 | Should BeOfType int;
            $result.par4.par45 | Should BeOfType string;
            $result.par4.par46 | Should BeOfType object;
            $result.par4.par47 | Should BeOfType object;
            $result.par4.par48 | Should BeOfType object;
            $result.par4.par49.par491 | Should BeOfType int;
            $result.par6 | Should BeOfType object;
            $result.par7 | Should Be 'hello world';
            $result.par8[2] | Should Be 20;
        }

        It "Should token replace nested parameters" {

            
            $parametersObject = [PSCustomObject]@{
                                    "general"= [PSCustomObject]@{
                                        "organization-name"= "org"
                                        "tenant-id"= "00000000-0000-0000-0000-000000000000"
                                        "deployment-user-id"= "00000000-0000-0000-0000-000000000000"
                                        "vdc-storage-account-name"= "storage"
                                        "vdc-storage-account-rg"= "vdc-storage-rg"
                                        "module-deployment-order"= @(
                                            "la",
                                            "nsg",
                                            "workload-net",
                                            "workload-kv",
                                            "sqldb",
                                            "ase"
                                        )
                                        "validation-dependencies"= @(
                                            "workload-kv"
                                        )
                                    }
                                    "on-premises"= [PSCustomObject]@{
                                        "address-range"= "192.168.1.0/28"
                                        "primaryDC-IP"= "192.168.1.4"
                                        "allow-rdp-address-range"= "192.168.1.4"
                                    }
                                    "shared-services"= [PSCustomObject]@{
                                        "subscription-id"= "00000000-0000-0000-0000-000000000000"
                                        "vnet-rg"= "org-ssvcs-net-rg"
                                        "vnet-name"= "org-ssvcs-vnet"
                                        "app-gateway-subnet-name"= "AppGateway"
                                        "app-gateway-name"= "org-ssvcs-app-gw"
                                        "gw-udr-name"= "org-ssvcs-gw-udr"
                                        "kv-rg"= "org-ssvcs-kv-rg"
                                        "kv-name"= "org-ssvcs-kv"
                                        "shared-services-subnet-address-prefix"= "10.4.0.32/27"
                                        "azure-firewall-private-ip-address"= "10.4.1.4"
                                        "azure-firewall-name"= "org-ssvcs-az-fw"
                                        "ubuntu-nva-lb-ip-address"= "10.4.0.20"
                                        "ubuntu-nva-address-start"= "10.4.0.5"
                                        "squid-nva-address-start"= "10.4.0.5"
                                        "deployment-name"= "ssvcs"
                                        "adds-address-start"= "10.4.0.46"
                                        "domain-name"= "contoso.com"
                                        "domain-admin-user"= "contoso"
                                        "network"= [PSCustomObject]@{
                                            "address-prefix"= "10.4.4.0/23"
                                            "application-security-groups"= @()
                                            "virtual-appliance"= [PSCustomObject]@{
                                                "egress-ip"= '${shared-services.network.virtual-appliance.azure-firewall.egress.ip}'
                                                "azure-firewall"= [PSCustomObject]@{
                                                    "ingress"= [PSCustomObject]@{
                                                        "vm-ip-address-start"= ""
                                                    }
                                                    "egress"= [PSCustomObject]@{
                                                        "ip"= "10.4.1.4"
                                                        "vm-ip-address-start"= ""
                                                    }
                                                }
                                                "palo-alto"= [PSCustomObject]@{
                                                    "ingress"= [PSCustomObject]@{
                                                        "vm-ip-address-start"= "10.4.0.43"
                                                    }
                                                    "egress"= [PSCustomObject]@{
                                                        "ip"= "10.4.0.50"
                                                        "vm-ip-address-start"= "10.4.0.40"
                                                    }
                                                    "image"= [PSCustomObject]@{
                                                        "offer"= "vmseries1"
                                                        "publisher"= "paloaltonetworks"
                                                        "sku"= "bundle2"
                                                        "version"= "latest"
                                                    }
                                                    "enable-bootstrap"= $True
                                                }
                                                "custom-ubuntu"= [PSCustomObject]@{
                                                    "ingress"= [PSCustomObject]@{
                                                        "vm-ip-address-start"= ""
                                                    }
                                                    "egress"= [PSCustomObject]@{
                                                        "ip"= "10.4.0.20"
                                                        "vm-ip-address-start"= "10.4.0.5"
                                                    }
                                                }
                                                "squid"= [PSCustomObject]@{
                                                    "ingress"= [PSCustomObject]@{
                                                        "vm-ip-address-start"= ""
                                                    }
                                                    "egress"= [PSCustomObject]@{
                                                        "ip"= ""
                                                        "vm-ip-address-start"= "10.4.0.5"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    "workload"= [PSCustomObject]@{
                                        "subscription-id"= "00000000-0000-0000-0000-000000000000"
                                        "deployment-name"= "paas"
                                        "region"= "Central US"
                                        "ancillary-region"= "East US"
                                        "log-analytics-region"= "West US 2"
                                        "local-admin-user"= "admin-user"
                                        "encryption-keys-for"= @()
                                        "enable-encryption"= $False
                                        "enable-ddos-protection"= $False
                                        "enable-vnet-peering"= $True
                                    }
                                }

            $tokenValues = [PSCustomObject]@{
                                    "general"= [PSCustomObject]@{
                                        "organization-name"= "org"
                                        "tenant-id"= "00000000-0000-0000-0000-000000000000"
                                        "deployment-user-id"= "00000000-0000-0000-0000-000000000000"
                                        "vdc-storage-account-name"= "storage"
                                        "vdc-storage-account-rg"= "vdc-storage-rg"
                                        "module-deployment-order"= @(
                                            "la",
                                            "nsg",
                                            "workload-net",
                                            "workload-kv",
                                            "sqldb",
                                            "ase"
                                        )
                                        "validation-dependencies"= @(
                                            "workload-kv"
                                        )
                                    }
                                    "on-premises"= [PSCustomObject]@{
                                        "address-range"= "192.168.1.0/28"
                                        "primaryDC-IP"= "192.168.1.4"
                                        "allow-rdp-address-range"= "192.168.1.4"
                                    }
                                    "shared-services"= [PSCustomObject]@{
                                        "subscription-id"= "00000000-0000-0000-0000-000000000000"
                                        "vnet-rg"= "org-ssvcs-net-rg"
                                        "vnet-name"= "org-ssvcs-vnet"
                                        "app-gateway-subnet-name"= "AppGateway"
                                        "app-gateway-name"= "org-ssvcs-app-gw"
                                        "gw-udr-name"= "org-ssvcs-gw-udr"
                                        "kv-rg"= "org-ssvcs-kv-rg"
                                        "kv-name"= "org-ssvcs-kv"
                                        "shared-services-subnet-address-prefix"= "10.4.0.32/27"
                                        "azure-firewall-private-ip-address"= "10.4.1.4"
                                        "azure-firewall-name"= "org-ssvcs-az-fw"
                                        "ubuntu-nva-lb-ip-address"= "10.4.0.20"
                                        "ubuntu-nva-address-start"= "10.4.0.5"
                                        "squid-nva-address-start"= "10.4.0.5"
                                        "deployment-name"= "ssvcs"
                                        "adds-address-start"= "10.4.0.46"
                                        "domain-name"= "contoso.com"
                                        "domain-admin-user"= "contoso"
                                        "network"= [PSCustomObject]@{
                                            "address-prefix"= "10.4.4.0/23"
                                            "application-security-groups"= @()
                                            "virtual-appliance"= [PSCustomObject]@{
                                                "egress-ip"= '${shared-services.network.virtual-appliance.azure-firewall.egress.ip}'
                                                "azure-firewall"= [PSCustomObject]@{
                                                    "ingress"= [PSCustomObject]@{
                                                        "vm-ip-address-start"= ""
                                                    }
                                                    "egress"= [PSCustomObject]@{
                                                        "ip"= "10.4.1.4"
                                                        "vm-ip-address-start"= ""
                                                    }
                                                }
                                                "palo-alto"= [PSCustomObject]@{
                                                    "ingress"= [PSCustomObject]@{
                                                        "vm-ip-address-start"= "10.4.0.43"
                                                    }
                                                    "egress"= [PSCustomObject]@{
                                                        "ip"= "10.4.0.50"
                                                        "vm-ip-address-start"= "10.4.0.40"
                                                    }
                                                    "image"= [PSCustomObject]@{
                                                        "offer"= "vmseries1"
                                                        "publisher"= "paloaltonetworks"
                                                        "sku"= "bundle2"
                                                        "version"= "latest"
                                                    }
                                                    "enable-bootstrap"= $True
                                                }
                                                "custom-ubuntu"= [PSCustomObject]@{
                                                    "ingress"= [PSCustomObject]@{
                                                        "vm-ip-address-start"= ""
                                                    }
                                                    "egress"= [PSCustomObject]@{
                                                        "ip"= "10.4.0.20"
                                                        "vm-ip-address-start"= "10.4.0.5"
                                                    }
                                                }
                                                "squid"= [PSCustomObject]@{
                                                    "ingress"= [PSCustomObject]@{
                                                        "vm-ip-address-start"= ""
                                                    }
                                                    "egress"= [PSCustomObject]@{
                                                        "ip"= ""
                                                        "vm-ip-address-start"= "10.4.0.5"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    "workload"= [PSCustomObject]@{
                                        "subscription-id"= "00000000-0000-0000-0000-000000000000"
                                        "deployment-name"= "paas"
                                        "region"= "Central US"
                                        "ancillary-region"= "East US"
                                        "log-analytics-region"= "West US 2"
                                        "local-admin-user"= "admin-user"
                                        "encryption-keys-for"= @()
                                        "enable-encryption"= $False
                                        "enable-ddos-protection"= $False
                                        "enable-vnet-peering"= $True
                                    }
                                }

            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.'shared-services'.'network'.'virtual-appliance'.'egress-ip' | Should Be '10.4.1.4';
        }

        It "Should replace string tokens" {

            
            $parametersObject =[PSCustomObject]@{   'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4'= [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44'= [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441}'
                                                                'par442'= '${shared-services.par442}'
                                                            }
                                                    }
                                                }

            $tokenValues =  [PSCustomObject]@{
                                'shared-services'= [PSCustomObject]@{
                                    'par441'= 'True'
                                    'par442'= '1'
                                }
                            }

            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $tokenReplacementService.HasTokens($result) | Should Be $False;
        }

        It "Should invalid token replacement" {
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4' = [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44' = [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.invalid_property}'
                                                            }
                                                    } } 
            $tokenValues = [PSCustomObject]@{ "shared-services"=  
                                                    [PSCustomObject]@{    
                                                        "par441" = [PSCustomObject]@{"boolValue" = $true}
                                                        "par442_intValue" = 1
                                                } }

            { $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues) } | Should Throw "cannot be resolved"
        }

        It "Should replace tokens that resolve to an empty array and no environment variables" {
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4' = [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44' = [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_emptyArray}'
                                                            }
                                                    } } 
            $tokenValues = [PSCustomObject]@{ "shared-services"=  
                                                    [PSCustomObject]@{    
                                                        "par441" = [PSCustomObject]@{"boolValue" = $true}
                                                        "par442_emptyArray" = @()
                                                } }

            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par442.Count | Should Be 0;
        }

        It "Should replace tokens that resolve to another token and no environment variables" {
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4' = [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44' = [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_token}'
                                                            }
                                                    } } 
            $tokenValues = [PSCustomObject]@{ "shared-services"=  
                                                    [PSCustomObject]@{    
                                                        "par441" = [PSCustomObject]@{"boolValue" = $true}
                                                        "par442_token" = '${shared-services.par443_stringValue}'
                                                        "par443_stringValue"= "resolvedValue"
                                                } }

            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par442 | Should Be 'resolvedValue'
        }

        It "Should replace composite token with two sub tokens that resolve to an object and string resp. and no environment variables" {
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4' = [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44' = [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_object}-${shared-services.par443_string}'
                                                            }
                                                    } } 
            $tokenValues = [PSCustomObject]@{ "shared-services"=  
                                                    [PSCustomObject]@{    
                                                        "par441" = [PSCustomObject]@{"boolValue" = $true}
                                                        "par442_object" = [PSCustomObject]@{ "a"= "b"}
                                                        "par443_string"= "sub-token-value"
                                                } }

            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par442 | Should Be "{""a"":""b""}-sub-token-value"
        }

        It "Should replace token that resolves to object with token and no environment variables" {
            $parametersObject = [PSCustomObject]@{  'par1'= 'value'
                                                    'par2'= $True
                                                    'par3'= 1
                                                    'par4' = [PSCustomObject]@{
                                                            'par41'= 'value41'
                                                            'par42'= $False
                                                            'par43'= 2
                                                            'par44' = [PSCustomObject]@{
                                                                'par441'= '${shared-services.par441.boolValue}'
                                                                'par442'= '${shared-services.par442_object}'
                                                            }
                                                    } } 
            $tokenValues = [PSCustomObject]@{ "shared-services"=  
                                                    [PSCustomObject]@{    
                                                        "par441" = [PSCustomObject]@{"boolValue" = $true}
                                                        "par442_object" = [PSCustomObject]@{ "a"= '${shared-services.par443_string}'}
                                                        "par443_string"= "token-value"
                                                } }

            $result = $tokenReplacementService.ReplaceAllTokens("shared-services", $parametersObject, $tokenValues);
            $result.par4.par44.par442.a | Should Be "token-value"
        }
    }
}
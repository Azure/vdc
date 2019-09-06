<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		module.tests.ps1

		Purpose:	Pester - Test SQL Managed Instance ARM Templates

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Azure SQL Managed Instance ARM template synatax.

	.DESCRIPTION
		This script contains functionality used to test Azure SQL Managed Instance ARM template synatax.

		Deployment steps of the script are outlined below.
        1) Test Template File Syntax
		2) Test Parameter File Syntax
		3) Test Template and Parameter File Compactibility
#>

#Requires -Version 5

#region Parameters

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Join-Path $here ".."
$template = Split-Path -Leaf $here
$TemplateFileTestCases = @()
ForEach ( $File in (Get-ChildItem (Join-Path "$here" "RBAC" -AdditionalChildPath @("deploy.json")) -ErrorAction SilentlyContinue -Recurse | Select-Object  -ExpandProperty Name) ) {
    $TemplateFileTestCases += @{ TemplateFile = $File }
}
$ParameterFileTestCases = @()
ForEach ( $File in (Get-ChildItem (Join-Path "$here" "RBAC" -AdditionalChildPath @("*parameters.json")) -ErrorAction SilentlyContinue -Recurse | Select-Object  -ExpandProperty Name) ) {
	$ParameterFileTestCases += @{ ParameterFile = Join-Path "RBAC" $File }
}
$Modules = @();
ForEach ( $File in (Get-ChildItem (Join-Path "$here" "RBAC" -AdditionalChildPath @("deploy.json")) -ErrorAction SilentlyContinue ) ) {
	$Module = [PSCustomObject]@{
		'Template' = $null
		'Parameters' = $null
	}
	$Module.Template = $File.FullName;
	$Parameters = @();
	ForEach ( $ParameterFile in (Get-ChildItem (Join-Path "$here" "RBAC" -AdditionalChildPath @("*parameters.json")) -Recurse | Select-Object  -ExpandProperty Name) ) {
		$Parameters += (Join-Path "$here" "RBAC" -AdditionalChildPath @("$ParameterFile") )
	}
	$Module.Parameters = $Parameters;
	$Modules += @{ Module = $Module };
}

#endregion

if ($null -ne $TemplateFileTestCases -and 
    $TemplateFileTestCases.Count -gt 0) { 

    #region Run Pester Test Script
    Describe "Template: $template - SQL Managed Instance" -Tags Unit {

        Context "Template File Syntax" {

            It "Has a JSON template file" -TestCases $TemplateFileTestCases {
                (Join-Path "$here" "deploy.json") | Should Exist
            }

            It "Converts from JSON and has the expected properties" -TestCases $TemplateFileTestCases {
                Param( $TemplateFile )
                Write-Host "TF: $TemplateFile"
                $expectedProperties = '$schema',
                'contentVersion',
                'parameters',
                'variables',
                'resources',
                'outputs' | Sort-Object
                $templateProperties = (Get-Content (Join-Path "$here" "$TemplateFile") `
                                        | ConvertFrom-Json -ErrorAction SilentlyContinue) `
                                        | Get-Member -MemberType NoteProperty `
                                        | Sort-Object -Property Name `
                                        | ForEach-Object Name
                $templateProperties | Should Be $expectedProperties
            }        
        }

        Context "Parameter File Syntax" {
        
            It "Parameter file does not contains the expected properties" -TestCases $ParameterFileTestCases {
                Param( $ParameterFile )
                $expectedProperties = '$schema',
                'contentVersion',
                'parameters' | Sort-Object
                Write-Host $ParameterFile
                Join-Path "$here" "$ParameterFile" | Write-Host
                $templateFileProperties = (Get-Content (Join-Path "$here" "$ParameterFile") `
                                            | ConvertFrom-Json -ErrorAction SilentlyContinue) `
                                            | Get-Member -MemberType NoteProperty `
                                            | Sort-Object -Property Name `
                                            | ForEach-Object Name
                $templateFileProperties | Should Be $expectedProperties 
            }
        }

        Context "Template and Parameter Compactibility" {

            It "Is count of required parameters in template file equal or lesser than count of all parameters in parameters file" -TestCases $Modules {
                Param( $Module )
                
                $requiredParametersInTemplateFile = (Get-Content "$($Module.Template)" `
                                | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
                                | Where-Object -FilterScript { -not ($_.Value.PSObject.Properties.Name -eq "defaultValue") } `
                                | Sort-Object -Property Name `
                                | ForEach-Object Name
                ForEach ( $Parameter in $Module.Parameters ) {
                    $allParametersInParametersFile = (Get-Content $Parameter `
                                | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
                                | Sort-Object -Property Name `
                                | ForEach-Object Name
                    $requiredParametersInTemplateFile.Count | Should Not BeGreaterThan $allParametersInParametersFile.Count;
                }
            }

            It "Has all parameters in parameters file existing in template file" -TestCases $Modules {
                Param( $Module )

                $allParametersInTemplateFile = (Get-Content "$($Module.Template)" `
                                | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
                                | Sort-Object -Property Name `
                                | ForEach-Object Name
                ForEach ( $Parameter in $Module.Parameters ) {
                    Write-Host "File analyzed: $Parameter";
                    $allParametersInParametersFile = (Get-Content $Parameter `
                                    | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
                                    | Sort-Object -Property Name `
                                    | ForEach-Object Name
                    $result = @($allParametersInParametersFile| Where-Object {$allParametersInTemplateFile -notcontains $_});
                    Write-Host "Invalid parameters: $(ConvertTo-Json $result)";
                    @($allParametersInParametersFile| Where-Object {$allParametersInTemplateFile -notcontains $_}).Count | Should Be 0;
                }
            }

            It "Has required parameters in template file existing in parameters file" -TestCases $Modules {
                Param( $Module )

                $requiredParametersInTemplateFile = (Get-Content "$($Module.Template)" `
                                | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
                                | Where-Object -FilterScript { -not ($_.Value.PSObject.Properties.Name -eq "defaultValue") } `
                                | Sort-Object -Property Name `
                                | ForEach-Object Name
                ForEach ( $Parameter in $Module.Parameters ) {
                    $allParametersInParametersFile = (Get-Content $Parameter `
                                    | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
                                    | Sort-Object -Property Name `
                                    | ForEach-Object Name
                    @($requiredParametersInTemplateFile| Where-Object {$allParametersInParametersFile -notcontains $_}).Count | Should Be 0;
                }
            }
        }

    }
    #endregion
}
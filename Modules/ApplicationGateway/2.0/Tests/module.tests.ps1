<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		application.gateway.module.tests.ps1

		Purpose:	Pester - Test Application Gateway Templates

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Application Gateway ARM template synatax.

	.DESCRIPTION
		This script contains functionality used to test Application Gateway ARM template synatax.

		Deployment steps of the script are outlined below.
        1) Test Template File Syntax
		2) Test Parameter File Syntax
		3) Test Template and Parameter File Compactibility
#>

#Requires -Version 5

#region - Parameters
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Join-Path $here ".."
$template = Split-Path -Leaf $here

$TemplateFileTestCases = @()
ForEach ($File in (Get-ChildItem (Join-Path "$here" "*deploy.json") | Select-Object -ExpandProperty Name)) {
    $TemplateFileTestCases += @{ TemplateFile = $File }
}

$ParameterFileTestCases = @()
ForEach ($File in (Get-ChildItem (Join-Path "$here" "*parameters*.json") | Select-Object -ExpandProperty Name)) {
    $ParameterFileTestCases += @{ ParameterFile = $File }
}
#endregion

#region - Run Pester Test Script
Describe "Template: $template - Application Gateway" -Tags Unit {
	
    Context "Template File Syntax" {
        It "Has a JSON template file" {
            (Join-Path "$here" "*deploy.json") | Should Exist
        }
		
        It "Converts from JSON and has the expected properties" -TestCases $TemplateFileTestCases {
            Param ($TemplateFile)
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
        It "Has environment parameters file" {
            (Join-Path "$here" "*parameters*.json") | Should Exist
        }
		
        It "Parameter file contains the expected properties" -TestCases $ParameterFileTestCases {
            Param ($ParameterFile)
            $expectedProperties = '$schema',
            'contentVersion',
            'parameters' | Sort-Object
            $templateFileProperties = (Get-Content (Join-Path "$here" "$ParameterFile") `
                | ConvertFrom-Json -ErrorAction SilentlyContinue) `
            | Get-Member -MemberType NoteProperty `
            | Sort-Object -Property Name `
            | ForEach-Object Name
            $templateFileProperties | Should Be $expectedProperties
        }
    }
	
    Context "Template and Parameter Compatibility" {
        BeforeEach {
            $Module = [PSCustomObject]@{
                'Template'   = $null
                'Parameters' = $null
            }
			
            ForEach ($File in (Get-ChildItem (Join-Path "$here" "*deploy.json") `
                    | Select-Object -ExpandProperty Name)) {
                $Module.Template = $File
            }
			
            ForEach ($File in (Get-ChildItem (Join-Path "$here" "*parameters*.json") `
                    | Select-Object -ExpandProperty Name)) {
                $Module.Parameters = $File
            }
        }
		
        It "Is count of required parameters in template file equal or lesser than count of all parameters in parameters file" {
			
            $requiredParametersInTemplateFile = (Get-Content (Join-Path "$here" "$($Module.Template)") `
                | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
            | Where-Object -FilterScript { -not ($_.Value.PSObject.Properties.Name -eq "defaultValue") } `
            | Sort-Object -Property Name `
            | ForEach-Object Name
            $allParametersInParametersFile = (Get-Content (Join-Path "$here" "$($Module.Parameters)") `
                | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
            | Sort-Object -Property Name `
            | ForEach-Object Name
            $requiredParametersInTemplateFile.Count | Should Not BeGreaterThan $allParametersInParametersFile.Count
        }
		
        It "Has all parameters in parameters file existing in template file" {
			
            $allParametersInTemplateFile = (Get-Content (Join-Path "$here" "$($Module.Template)") `
                | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
            | Sort-Object -Property Name `
            | ForEach-Object Name
            $allParametersInParametersFile = (Get-Content (Join-Path "$here" "$($Module.Parameters)") `
                | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
            | Sort-Object -Property Name `
            | ForEach-Object Name
            @($allParametersInParametersFile | Where-Object { $allParametersInTemplateFile -notcontains $_ }).Count | Should Be 0
        }
		
        It "Has required parameters in template file existing in parameters file" {
			
            $requiredParametersInTemplateFile = (Get-Content (Join-Path "$here" "$($Module.Template)") `
                | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
            | Where-Object -FilterScript { -not ($_.Value.PSObject.Properties.Name -eq "defaultValue") } `
            | Sort-Object -Property Name `
            | ForEach-Object Name
            $allParametersInParametersFile = (Get-Content (Join-Path "$here" "$($Module.Parameters)") `
                | ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
            | Sort-Object -Property Name `
            | ForEach-Object Name
            @($requiredParametersInTemplateFile | Where-Object { $allParametersInParametersFile -notcontains $_ }).Count | Should Be 0
        }
    }
}
#endregion
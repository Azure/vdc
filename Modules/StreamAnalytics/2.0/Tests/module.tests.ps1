<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		module.tests.ps1

		Purpose:	Pester - Test Stream Analytics ARM Templates

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Stream Analytics ARM template synatax.

	.DESCRIPTION
		This script contains functionality used to test Stream Analytics ARM template synatax.

		Deployment steps of the script are outlined below.
        1) Test Template File Syntax
		2) Test Parameter File Syntax
		3) Test Template and Parameter File Compactibility
#>

#Requires -Version 5

#region Parameters
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$here = Join-Path -Path $here -ChildPath ".."
$template = Split-Path -Leaf $here

#region - Template File Test Cases
$templateFileTestCases = @()
ForEach ($file in (Get-ChildItem (Join-Path -Path "$here" -ChildPath "deploy.json") -Recurse | Select-Object  -ExpandProperty Name)) {
    $templateFileTestCases += @{ TemplateFile = $file }
}
#endregion

#region - Parameter File Test Cases
$parameterFileTestCases = @()
ForEach ($file in (Get-ChildItem (Join-Path -Path "$here" -ChildPath "Tests" -AdditionalChildPath @("*parameters.json")) -Recurse -ErrorAction SilentlyContinue | Select-Object  -ExpandProperty Name)) {
	$parameterFileTestCases += @{ ParameterFile = Join-Path -Path "Tests" $file }
}
#endregion

#region - Module Test Cases
$modules = @()
ForEach ($file in (Get-ChildItem (Join-Path -Path "$here" -ChildPath "deploy.json"))) {
	$module = [PSCustomObject]@{
		'Template' = $null
		'Parameters' = $null
	}
	$module.Template = $file.FullName

	$parameters = @()
	ForEach ($parameterFile in (Get-ChildItem (Join-Path -Path "$here" -ChildPath "Tests" -AdditionalChildPath @("*parameters.json")) -Recurse -ErrorAction SilentlyContinue | Select-Object  -ExpandProperty Name)) {
		$parameters += (Join-Path -Path "$here" -ChildPath "Tests" -AdditionalChildPath @("$ParameterFile"))
	}
	$Module.Parameters = $Parameters
	$Modules += @{Module = $Module}
}
#endregion

#endregion

#region - Run Pester Test Script
Describe "Template: $template - Stream Analytics" -Tags -Unit {

	#region - Template File Syntax
    Context "Template File Syntax" {

        It "Has a JSON template file" {
            (Join-Path -Path "$here" -ChildPath "deploy.json") | Should -Exist
        }

        It "Converts from JSON and has the expected properties" -TestCases $templateFileTestCases {
            param($templateFile)
			$expectedProperties = '$schema',
			'contentVersion',
            'parameters',
            'variables',
			'resources',
			'outputs' | Sort-Object
			$templateProperties = (Get-Content (Join-Path -Path "$here" -ChildPath "$templateFile") `
					| ConvertFrom-Json -ErrorAction SilentlyContinue) `
					| Get-Member -MemberType NoteProperty `
					| Sort-Object -Property Name `
					| ForEach-Object Name
            $templateProperties | Should -Be $expectedProperties
        }
    }
	#endregion

	#region - Parameter File Syntax
    Context "Parameter File Syntax" {

		It "Parameter file does not contains the expected properties" -TestCases $parameterFileTestCases {
            param($parameterFile)
            $expectedProperties = '$schema',
            'contentVersion',
			'parameters' | Sort-Object
			Write-Output $parameterFile
			Join-Path -Path "$here" -ChildPath "$parameterFile" | Write-Output
			$templateFileProperties = (Get-Content (Join-Path -Path "$here" -ChildPath "$parameterFile") `
					| ConvertFrom-Json -ErrorAction SilentlyContinue) `
					| Get-Member -MemberType NoteProperty `
					| Sort-Object -Property Name `
					| ForEach-Object Name
            $templateFileProperties | Should -Be $expectedProperties
        }
    }
	#endregion

	#region - Template and Parameter Compactibility
	Context "Template and Parameter Compactibility" {

		It "Is count of required parameters in template file equal or lesser than count of all parameters in parameters file" -TestCases $modules {
			param($module)
			$requiredParametersInTemplateFile = (Get-Content "$($module.Template)" `
					| ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
					| Where-Object -FilterScript { -not ($psitem.Value.PSObject.Properties.Name -eq "defaultValue")} `
					| Sort-Object -Property Name `
					| ForEach-Object Name
			ForEach ( $parameter in $module.Parameters ) {
				$allParametersInParametersFile = (Get-Content $parameter `
					| ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
					| Sort-Object -Property Name `
					| ForEach-Object Name
				$requiredParametersInTemplateFile.Count | Should -Not -BeGreaterThan $allParametersInParametersFile.Count
			}
		}

		It "Has all parameters in parameters file existing in template file" -TestCases $modules {
			param($module)
			$allParametersInTemplateFile = (Get-Content "$($module.Template)" `
					| ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
					| Sort-Object -Property Name `
					| ForEach-Object Name
			ForEach ($parameter in $module.Parameters) {
				Write-Output "File analyzed: $parameter"
				$allParametersInParametersFile = (Get-Content $parameter `
					| ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
					| Sort-Object -Property Name `
					| ForEach-Object Name
				$result = @($allParametersInParametersFile| Where-Object {$allParametersInTemplateFile -notcontains $psitem})
				Write-Output "Invalid parameters: $(ConvertTo-Json $result)"
				@($allParametersInParametersFile| Where-Object {$allParametersInTemplateFile -notcontains $psitem}).Count | Should -Be 0
			}
		}

		It "Has required parameters in template file existing in parameters file" -TestCases $modules {
			param($module)
			$requiredParametersInTemplateFile = (Get-Content "$($module.Template)" `
					| ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
					| Where-Object -FilterScript { -not ($psitem.Value.PSObject.Properties.Name -eq "defaultValue") } `
					| Sort-Object -Property Name `
					| ForEach-Object Name
			ForEach ($parameter in $module.Parameters ) {
				$allParametersInParametersFile = (Get-Content $parameter `
					| ConvertFrom-Json -ErrorAction SilentlyContinue).Parameters.PSObject.Properties `
					| Sort-Object -Property Name `
					| ForEach-Object Name
				@($requiredParametersInTemplateFile| Where-Object {$allParametersInParametersFile -notcontains $psitem}).Count | Should -Be 0
			}
		}
	}
	#endregion
}
#endregion
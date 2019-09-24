<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		output.tests.ps1

		Purpose:	Test - Cognitive Services ARM Template Output Variables

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Cognitive Services ARM Templates output variables.

	.DESCRIPTION
		This script contains functionality used to test Cognitive Services ARM Templates output variables.

		Deployment steps of the script are outlined below.
            1) Outputs Variable Logic from pipeline

	.PARAMETER cognitiveServicesName
		Specify the Cognitive Services Name output parameter.

	.PARAMETER cognitiveServicesResourceId
		Specify the Cognitive Services ResourceId output parameter.

	.PARAMETER cognitiveServicesResourceGroup
		Specify the Cognitive Services ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\output.tests.ps1
			-cognitiveServicesName "$(cognitiveServicesName)"
			-cognitiveServicesResourceId "$(cognitiveServicesResourceId)"
			-cognitiveServicesResourceGroup "$(cognitiveServicesResourceGroup)"
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$cognitiveServicesName,

	[Parameter(Mandatory = $false)]
	[string]$cognitiveServicesResourceId,

	[Parameter(Mandatory = $false)]
	[string]$cognitiveServicesResourceGroup
)

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['cognitiveServicesName']))
{
	Write-Output "Cognitive Services Name: $($cognitiveServicesName)"
}
else
{
	Write-Output "Cognitive Services Name: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['cognitiveServicesResourceId']))
{
	Write-Output "Cognitive Services ResourceId: $($cognitiveServicesResourceId)"
}
else
{
	Write-Output "Cognitive Services ResourceId: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['cognitiveServicesResourceGroup']))
{
	Write-Output "Cognitive Services Resource Group: $($cognitiveServicesResourceGroup)"
}
else
{
	Write-Output "Cognitive Services Resource Group: []"
}
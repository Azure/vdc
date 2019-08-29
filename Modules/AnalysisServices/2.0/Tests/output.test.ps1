<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		output.test.ps1

		Purpose:	Test - Analysis Services ARM Template Output Variables

		Version: 	2.0.0.0 - 1st August 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Analysis Services ARM Templates output variables.

	.DESCRIPTION
		This script contains functionality used to test Analysis Services ARM Templates output variables.

		Deployment steps of the script are outlined below.
            1) Outputs Variable Logic from pipeline

	.PARAMETER analysisServicesName
		Specify the Analysis Services Name output parameter.

	.PARAMETER analysisServicesResourceId
		Specify the Analysis Services ResourceId output parameter.

	.PARAMETER analysisServicesResourceGroup
		Specify the Analysis Services ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\output.test.ps1
			-analysisServicesName "$(analysisServicesName)"
			-analysisServicesResourceId "$(analysisServicesResourceId)"
			-analysisServicesResourceGroup "$(analysisServicesResourceGroup)"
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$analysisServicesName,

	[Parameter(Mandatory = $false)]
	[string]$analysisServicesResourceId,

	[Parameter(Mandatory = $false)]
	[string]$analysisServicesResourceGroup
)

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['analysisServicesName']))
{
	Write-Output "Analysis Services Name: $($analysisServicesName)"
}
else
{
	Write-Output "Analysis Services Name: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['analysisServicesResourceId']))
{
	Write-Output "Analysis Services ResourceId: $($analysisServicesResourceId)"
}
else
{
	Write-Output "Analysis Services ResourceId: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['analysisServicesResourceGroup']))
{
	Write-Output "Analysis Services Resource Group: $($analysisServicesResourceGroup)"
}
else
{
	Write-Output "Analysis Services Resource Group: []"
}
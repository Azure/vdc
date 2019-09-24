<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		stream.analytics.output.tests.ps1

		Purpose:	Test - Stream Analytics ARM Template Output Variables

		Version: 	2.0.0.0 - 1st August 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Stream Analytics ARM Templates output variables.

	.DESCRIPTION
		This script contains functionality used to test Stream Analytics ARM Templates output variables.

		Deployment steps of the script are outlined below.
            1) Outputs Variable Logic from pipeline

	.PARAMETER streamAnalyticsName
		Specify the Stream Analytics Name output parameter.

	.PARAMETER streamAnalyticsResourceId
		Specify the Stream Analytics ResourceId output parameter.

	.PARAMETER streamAnalyticsResourceGroup
		Specify the Stream Analytics ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\stream.analytics.output.tests.ps1
			-streamAnalyticsName "$(streamAnalyticsName)"
			-streamAnalyticsResourceId "$(streamAnalyticsResourceId)"
			-streamAnalyticsResourceGroup "$(streamAnalyticsResourceGroup)"
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$streamAnalyticsName,

	[Parameter(Mandatory = $false)]
	[string]$streamAnalyticsResourceId,

	[Parameter(Mandatory = $false)]
	[string]$streamAnalyticsResourceGroup
)

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['streamAnalyticsName']))
{
	Write-Output "Stream Analytics Name: $($streamAnalyticsName)"
}
else
{
	Write-Output "Stream Analytics Name: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['streamAnalyticsResourceId']))
{
	Write-Output "Stream Analytics ResourceId: $($streamAnalyticsResourceId)"
}
else
{
	Write-Output "Stream Analytics ResourceId: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['streamAnalyticsResourceGroup']))
{
	Write-Output "Stream Analytics Resource Group: $($streamAnalyticsResourceGroup)"
}
else
{
	Write-Output "Stream Analytics Resource Group: []"
}
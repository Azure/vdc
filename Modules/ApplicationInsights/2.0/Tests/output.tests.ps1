<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		output.tests.ps1

		Purpose:	Test - Application Insights ARM Template Output Variables

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Application Insights ARM Template Output Variables.

	.DESCRIPTION
		This script contains functionality used to test Application Insights ARM Template Output Variables.

		Deployment steps of the script are outlined below.
            1) Outputs Variable Logic from pipeline

	.PARAMETER appInsightsName
		Specify the Application Insights Name output parameter.

	.PARAMETER appInsightsResourceId
		Specify the Application Insights Resource Id output parameter.

	.PARAMETER appInsightsResourceGroup
		Specify the Application Insights ResourceGroup output parameter.

	.PARAMETER appInsightsKey
		Specify the Application Insights Instrumentation Key output parameter.

	.PARAMETER appInsightsAppId
		Specify the Application Insights AppId output parameter.

    .PARAMETER appInsightsStorageAccountName
		Specify the Application Storage Account Name output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\output.tests.ps1
            -appInsightsName "$(appInsightsName)"
			-appInsightsResourceId "$(appInsightsResourceId)"
			-appInsightsResourceGroup "$(appInsightsResourceGroup)"
            -appInsightsKey "$(appInsightsKey)"
            -appInsightsAppId "$(appInsightsAppId)"
            -appInsightsStorageAccountName "$(appInsightsStorageAccountName)"
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$appInsightsName,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsResourceId,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsResourceGroup,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsKey,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsAppId,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsStorageAccountName
)

#region - Application Insights Output Tests

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsName']))
{
	Write-Output "Application Insights Name: $($appInsightsName)"
}
else
{
	Write-Output "Application Insights Name: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsResourceId']))
{
	Write-Output "Application Insights ResourceId: $($appInsightsResourceId)"
}
else
{
	Write-Output "Application Insights Resource Id: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsResourceGroup']))
{
	Write-Output "Application Insights ResourceGroup: $($appInsightsResourceGroup)"
}
else
{
	Write-Output "Application Insights ResourceGroup: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsKey']))
{
	Write-Output "Application Insights Instrumentation Key: $($appInsightsKey)"
}
else
{
	Write-Output "Application Insights Instrumentation Key: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsAppId']))
{
	Write-Output "Application Insights AppId: $($appInsightsAppId)"
}
else
{
	Write-Output "Application Insights AppId: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsStorageAccountName']))
{
	Write-Output "Application Insights Storage Account Name: $($appInsightsStorageAccountName)"
}
else
{
	Write-Output "Application Insights Storage Account Name: []"
}
#endregion
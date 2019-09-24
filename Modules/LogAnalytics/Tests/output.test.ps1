<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		output.test.ps1

		Purpose:	Test - Log Analytics ARM Template Output Variables

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Log Analytics ARM template output variables.

	.DESCRIPTION
		This script contains functionality used to test Log Analytics ARM template output variables.

		Deployment steps of the script are outlined below.
			1) Outputs Variable Logic to pipeline

	.PARAMETER logAnalyticsWorkspaceName
		Specify the Log Analytics Workspace Name output parameter.

	.PARAMETER logAnalyticsWorkspaceResourceId
		Specify the Log Analytics Resource Id output parameter.

	.PARAMETER logAnalyticsWorkspaceResourceGroup
		Specify the Log Analytics Workspace Resource Group output parameter.

	.PARAMETER logAnalyticsWorkspaceId
		Specify the Log Analytics Workspace Id output parameter.
   
	.PARAMETER logAnalyticsPrimarySharedKey
		Specify the Log Analytics Workspace Id output parameter.
 
	.EXAMPLE
		Default:
		C:\PS>.\logAnalytics.output.test.ps1 `
			-logAnalyticsWorkspaceName <"logAnalyticsWorkspaceName"> `
			-logAnalyticsWorkspaceResourceId <"logAnalyticsWorkspaceResourceId"> `
			-logAnalyticsWorkspaceResourceGroup <"logAnalyticsWorkspaceResourceGroup"> `
			-logAnalyticsWorkspaceId <"logAnalyticsWorkspaceId"> `
			-logAnalyticsPrimarySharedKey <"logAnalyticsPrimarySharedKey">
#>

#Requires -Version 5

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [string]$logAnalyticsWorkspaceName,
	[Parameter(Mandatory = $false)]
    [string]$logAnalyticsWorkspaceResourceId,
	[Parameter(Mandatory = $false)]
    [string]$logAnalyticsWorkspaceResourceGroup,
	[Parameter(Mandatory = $false)]
    [string]$logAnalyticsWorkspaceId,
	[Parameter(Mandatory = $false)]
    [string]$logAnalyticsPrimarySharedKey
)

if($logAnalyticsWorkspaceName -ne $null)
{
    write-output "Log Analytics Workspace Name: $($LogAnalyticsWorkspaceName)" 
}
else
{
    write-output "Log Analytics Workspace Name: NULL"
}

if($logAnalyticsWorkspaceResourceId -ne $null)
{
    write-output "Log Analytics Resource Id: $($logAnalyticsWorkspaceResourceId)" 
}
else
{
    write-output "Log Analytics Resource Id: NULL"
}

if($logAnalyticsWorkspaceResourceGroup -ne $null) {

    write-output "Log Analytics Workspace Resource Group: $($logAnalyticsWorkspaceResourceGroup)" 
}
else
{
    write-output "Log Analytics Workspace Resource Group: NULL"
}

if($logAnalyticsWorkspaceId -ne $null)
{
    write-output "Log Analytics Workspace Id: $($logAnalyticsWorkspaceId)" 
}
else
{
    write-output "Log Analytics Workspace Id: NULL"
}

if($logAnalyticsPrimarySharedKey -ne $null)
{
    write-output "Log Analytics Primary Shared Key: $($logAnalyticsPrimarySharedKey)" 
}
else
{
    write-output "Log Analytics Primary Shared Key: NULL"
}
<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		output.tests.ps1

		Purpose:	Test - EventHub Namespace ARM Template Output Variables

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test EventHub Namespace ARM Templates output variables.

	.DESCRIPTION
		This script contains functionality used to test EventHub Namespace ARM Templates output variables.

		Deployment steps of the script are outlined below.
            1) Outputs Variable Logic from pipeline

	.PARAMETER namespaceName
		Specify the EventHub Namespace Name output parameter.

	.PARAMETER namespaceResourceId
		Specify the EventHub Namespace ResourceId output parameter.

	.PARAMETER namespaceResourceGroup
		Specify the EventHub Namespace ResourceGroup output parameter.

	.PARAMETER namespaceConnectionString
		Specify the EventHub Namespace Connection String output parameter.

	.PARAMETER sharedAccessPolicyPrimaryKey
		Specify the EventHub Namespace Shared Access Policy Primary Key output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\output.tests.ps1
			-namespaceName "$(namespaceName)"
			-namespaceResourceId "$(namespaceResourceId)"
			-namespaceResourceGroup "$(namespaceResourceGroup)"
			-namespaceConnectionString "$(namespaceConnectionString)"
            -sharedAccessPolicyPrimaryKey "$(sharedAccessPolicyPrimaryKey)"
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$namespaceName,

	[Parameter(Mandatory = $false)]
	[string]$namespaceResourceId,

	[Parameter(Mandatory = $false)]
	[string]$namespaceResourceGroup,

	[Parameter(Mandatory = $false)]
    [string]$namespaceConnectionString,

    [Parameter(Mandatory = $false)]
    [string]$sharedAccessPolicyPrimaryKey
)

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['namespaceName']))
{
	Write-Output "EventHub Namespace Name: $($namespaceName)"
}
else
{
	Write-Output "EventHub Namespace Name: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['namespaceResourceId']))
{
	Write-Output "EventHub Namespace ResourceId: $($namespaceResourceId)"
}
else
{
	Write-Output "EventHub Namespace ResourceId: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['namespaceResourceGroup']))
{
	Write-Output "EventHub Namespace Resource Group: $($namespaceResourceGroup)"
}
else
{
	Write-Output "EventHub Namespace Resource Group: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['namespaceConnectionString']))
{
	Write-Output "EventHub Namespace ConnectionString: $namespaceConnectionString"
}
else
{
	Write-Output "EventHub Namespace ConnectionString: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['sharedAccessPolicyPrimaryKey']))
{
	Write-Output "EventHub Namespace Shared Access Policy Primary Key: $sharedAccessPolicyPrimaryKey"
}
else
{
	Write-Output "EventHub Namespace Shared Access Policy Primary Key: []"
}
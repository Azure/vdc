<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		output.test.ps1

		Purpose:	Test - API Management Service ARM Template Output Variables

		Version: 	2.0.0.0 - 1st August 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test API Management Service ARM Templates output variables.

	.DESCRIPTION
		This script contains functionality used to test API Management Service ARM Templates output variables.

		Deployment steps of the script are outlined below.
            1) Outputs Variable Logic from pipeline

	.PARAMETER apimServiceName
		Specify the API Management Service Name output parameter.

	.PARAMETER apimServiceResourceId
		Specify the API Management Service ResourceId output parameter.

	.PARAMETER apimServiceResourceGroup
		Specify the API Management Service ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\output.test.ps1
			-apimServiceName "$(apimServiceName)"
			-apimServiceResourceId "$(apimServiceResourceId)"
			-apimServiceResourceGroup "$(apimServiceResourceGroup)"
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
    [string]$apimServiceName,

    [Parameter(Mandatory = $false)]
    [string]$apimServiceResourceId,

	[Parameter(Mandatory = $false)]
    [string]$apimServiceResourceGroup
)

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['apimServiceName']))
{
    Write-Output "API Management Service Name: $($apimServiceName)"
}
else
{
    Write-Output "API Management Service Name: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['apimServiceResourceId']))
{
    Write-Output "API Management Service ResourceId: $($apimServiceResourceId)"
}
else
{
    Write-Output "API Management Service ResourceId: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['apimServiceResourceGroup']))
{
	Write-Output "API Management Service Resource Group: $($apimServiceResourceGroup)"
}
else
{
    Write-Output "API Management Service Resource Group: []"
}
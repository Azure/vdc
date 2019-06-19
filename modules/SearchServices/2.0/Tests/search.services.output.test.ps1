<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		search.services.output.test.ps1

		Purpose:	Test - Search Services ARM Template Output Variables

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Search Services ARM template output variables.

	.DESCRIPTION
		This script contains functionality used to test Search Services ARM template output variables.

		Deployment steps of the script are outlined below.
			1) Outputs Variable Logic to pipeline

	.PARAMETER AzureSearchName
		Specify the Azure Search Name output parameter.

	.PARAMETER AzureSearchResourceGroup
		Specify the Azure Search Resource Group output parameter.
		
	.EXAMPLE
		Default:
		C:\PS>.\search.services.output.test.ps1 `
			-AzureSearchName <"AzureSearchName"> `
			-AzureSearchResourceGroup <"AzureSearchResourceGroup">
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
    [string]$AzureSearchName,

	[Parameter(Mandatory = $false)]
    [string]$AzureSearchResourceGroup
)

if($AzureSearchName -ne $null)
{
    write-output "Azure Search Name: $($AzureSearchName)"
}
else
{
    write-output "Azure Search Name: NULL"
}

if($AzureSearchResourceGroup -ne $null)
{
    write-output "Azure Search Resource Group: $($AzureSearchResourceGroup)"
}
else
{
    write-output "Azure Search Resource Group: NULL"
}
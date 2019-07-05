<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		output.test.ps1

		Purpose:	Test - Azure Firewall ARM Template Output Variables

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Azure Firewall ARM template output variables.

	.DESCRIPTION
		This script contains functionality used to test Azure Firewall ARM template output variables.

		Deployment steps of the script are outlined below.
			1) Outputs Variable Logic to pipeline

	.PARAMETER AzureFirewallResourceId
		Specify the Azure Firewall Workspace Name output parameter.
	
	.EXAMPLE
		Default:
		C:\PS>.\azure.firewall.output.test.ps1 `
			-AzureFirewallResourceId <"AzureFirewallResourceId"> 
#>

#Requires -Version 5

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [string]$AzureFirewallResourceId
)

if($AzureFirewallResourceId -ne $null)
{
    write-output "Azure Firewall Resource Id: $($AzureFirewallResourceId)" 
}
else
{
    write-output "Azure Firewall Resource Id: NULL"
}
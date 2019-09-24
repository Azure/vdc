<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		output.test.ps1

		Purpose:	Test - Key Vault ARM Template Output Variables

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Key Vault ARM template output variables.

	.DESCRIPTION
		This script contains functionality used to test Key Vault ARM template output variables.

		Deployment steps of the script are outlined below.
			1) Outputs Variable Logic to pipeline

	.PARAMETER KeyVaultName
		Specify the Key Vault Name output parameter.
	
	.EXAMPLE
		Default:
		C:\PS>.\output.test.ps1 `
			-KeyVaultName <"KeyVaultName"> 
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
    [string]$KeyVaultName
)  
  
if($KeyVaultName -ne $null)
{
    write-output "Azure Key Vault Name: $($KeyVaultName)"
}
else
{
    write-output "Azure Key Vault Name: NULL"
}
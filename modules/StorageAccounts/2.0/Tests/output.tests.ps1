<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		output.tests.ps1

		Purpose:	Test - Storage Account ARM Template Output Variables

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Storage Account ARM template output variables.

	.DESCRIPTION
		This script contains functionality used to test Storage Account ARM template output variables.

		Deployment steps of the script are outlined below.
			1) Outputs Variable Logic to pipeline

	.PARAMETER StorageAccountName
		Specify the Storage Account Name output parameter.
	
	.EXAMPLE
		Default:
		C:\PS>.\output.tests.ps1 `
			-StorageAccountName <"StorageAccountName"> 
#>

#Requires -Version 5

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName
)

if($StorageAccountName -ne $null)
{
    write-output "Storage Account Name: $($StorageAccountName)" 
}
else
{
    write-output "Storage Account Name: NULL"
}
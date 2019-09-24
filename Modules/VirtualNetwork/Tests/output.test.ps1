<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		vnet.output.test.ps1

		Purpose:	Test - Virtual Network ARM Template Output Variables

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Virtual Network ARM template output variables.

	.DESCRIPTION
		This script contains functionality used to test Virtual Network ARM template output variables.

		Deployment steps of the script are outlined below.
			1) Outputs Variable Logic to pipeline

	.PARAMETER vNetResourceGroup
		Specify the Virtual Nwetwoek Resource Group Name output parameter.
	
	.PARAMETER vNetName
		Specify the Virtual Network Name output parameter.
	
	.EXAMPLE
		Default:
		C:\PS>.\vNet.output.test.ps1 `
			-vNetResourceGroup <"vNetResourceGroup"> 
			-vNetName <"vNetName">
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
    [string]$vNetResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$vNetName
)  
  
 
if($vNetResourceGroup -ne $null)
{
    write-output "Virtual Network Resource Group Name: $($vNetResourceGroup)"
}
else
{
    write-output "Virtual Network Resource Group Name: NULL"
}

if($vNetName -ne $null)
{
    write-output "Virtual Network Name: $($vNetName)"
}
else
{
    write-output "Virtual Network Name: NULL"
}

<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		output.tests.ps1

		Purpose:	Test - Machine Learning ARM Template Output Variables

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Machine Learning ARM Template Output Variables.

	.DESCRIPTION
		This script contains functionality used to test Machine Learning ARM Template Output Variables.

		Deployment steps of the script are outlined below.
            1) Outputs Variable Logic from pipeline

	.PARAMETER machinelearningName
		Specify the Machine Learning Name output parameter.

	.PARAMETER machinelearningResourceId
		Specify the Machine Learning Resource Id output parameter.

	.PARAMETER machinelearningResourceGroup
		Specify the Machine Learning ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\output.tests.ps1
            -machinelearningName "$(machinelearningName)"
			-machinelearningResourceId "$(machinelearningResourceId)"
			-machinelearningResourceGroup "$(machinelearningResourceGroup)"
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$machinelearningName,

	[Parameter(Mandatory = $false)]
	[string]$machinelearningResourceId,

	[Parameter(Mandatory = $false)]
	[string]$machinelearningResourceGroup
)

#region - Machine Learning Output Tests

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['machinelearningName']))
{
	Write-Output "Machine Learning Name: $($machinelearningName)"
}
else
{
	Write-Output "Machine Learning Name: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['machinelearningResourceId']))
{
	Write-Output "Machine Learning ResourceId: $($machinelearningResourceId)"
}
else
{
	Write-Output "Machine Learning Resource Id: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['machinelearningResourceGroup']))
{
	Write-Output "Machine Learnings ResourceGroup: $($machinelearningResourceGroup)"
}
else
{
	Write-Output "Machine Learning ResourceGroup: []"
}
#endregion
<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		machine.learning.akv.secrects.ps1

		Purpose:	Set Machine Learning  KeyVault Secrets Automation Script

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		Set Machine Learning  KeyVault Secrets Automation Script

	.DESCRIPTION
		Set Machine Learning  KeyVault Secrets Automation Script

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Machine Learning Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER machinelearningName
		Specify the Machine Learning Name output parameter.

	.PARAMETER machinelearningResourceId
		Specify the Machine Learning Resource Id output parameter.

	.PARAMETER machinelearningResourceGroup
		Specify the Machine Learning ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\machine.learning.akv.secrects.ps1
			-keyVaultName "$(keyVaultName)"
            -machinelearningName "$(machinelearningName)"
			-machinelearningResourceId "$(machinelearningResourceId)"
			-machinelearningResourceGroup "$(machinelearningResourceGroup)"
#>

#Requires -Version 5
#Requires -Module Az.KeyVault
#Requires -Module Az.Resources

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$machinelearningName,

	[Parameter(Mandatory = $false)]
	[string]$machinelearningResourceId,

	[Parameter(Mandatory = $false)]
	[string]$machinelearningResourceGroup
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name : $keyVaultName"
	$kVSecretParameters = @{ }

	#region - Machine Learning Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['machinelearningName']))
	{
		Write-Output "Machine Learning Name: $machinelearningName"
		$kVSecretParameters.Add("MachineLearning--Name", $($machinelearningName))
	}
	else
	{
		Write-Output "Machine Learning Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['machinelearningResourceId']))
	{
		Write-Output "Machine Learning ResourceId: $machinelearningResourceId"
		$kVSecretParameters.Add("MachineLearning--ResourceId", $($machinelearningResourceId))
	}
	else
	{
		Write-Output "Machine Learning ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['machinelearningResourceGroup']))
	{
		Write-Output "Machine Learning ResourceGroup: $machinelearningResourceGroup"
		$kVSecretParameters.Add("MachineLearning--ResourceGroup", $($machinelearningResourceGroup))
	}
	else
	{
		Write-Output "Machine Learning ResourceGroup: []"
	}
	#endregion

	#region - Set Azure KeyVault Secret
	$kVSecretParameters.Keys | ForEach-Object {
		$key = $psitem
		$value = $kVSecretParameters.Item($psitem)

		if (-not [string]::IsNullOrWhiteSpace($value))
		{
			Write-Output "KeyVault Secret: $key : $value"

			$value = $kVSecretParameters.Item($psitem)

			Write-Output "Setting Secret for $key"
			$paramSetAzKeyVaultSecret = @{
				VaultName   = $keyVaultName
				Name	    = $key
				SecretValue = (ConvertTo-SecureString $value -AsPlainText -Force)
				Verbose	    = $true
				ErrorAction = 'SilentlyContinue'
			}
			Set-AzKeyVaultSecret @paramSetAzKeyVaultSecret
		}
		else
		{
			Write-Output "KeyVault Secret: []"
		}
	}
	#endregion
}
else
{
	Write-Output "KeyVault Name: []"
}
#endregion
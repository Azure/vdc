<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		analysis.services.akv.secrects.ps1

		Purpose:	Set Analysis Services Secrets Automation Script

		Version: 	2.0.0.0 - 1st August 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		Set Analysis Services Key Vault Secrets Automation Script

	.DESCRIPTION
		Set Analysis Services Key Vault Secrets Automation Script

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Analysis Services Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER analysisServicesName
		Specify the Analysis Services Name output parameter.

	.PARAMETER analysisServicesResourceId
		Specify the Analysis Services ResourceId output parameter.

	.PARAMETER analysisServicesResourceGroup
		Specify the Analysis Services ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\analysis.services.akv.secrects.ps1
			-keyVaultName "$(keyVaultName)"
			-analysisServicesName "$(analysisServicesName)"
			-analysisServicesResourceId "$(analysisServicesResourceId)"
			-analysisServicesResourceGroup "$(analysisServicesResourceGroup)"
#>

#Requires -Version 5
#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$analysisServicesName,

	[Parameter(Mandatory = $false)]
	[string]$analysisServicesResourceId,

	[Parameter(Mandatory = $false)]
	[string]$analysisServicesResourceGroup
)

#region - Key Vault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kVSecretParameters = @{ }

	#region - Analysis Services Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['analysisServicesName']))
	{
		Write-Output "Analysis Services Name : $analysisServicesName"
		$kVSecretParameters.Add("AnalysisServices--Name", $($analysisServicesName))
	}
	else
	{
		Write-Output "Analysis Services Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['analysisServicesResourceId']))
	{
		Write-Output "AnalysisServices ResourceId : $analysisServicesResourceId"
		$kVSecretParameters.Add("AnalysisServices--ResourceId", $($analysisServicesResourceId))
	}
	else
	{
		Write-Output "Analysis Services ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['analysisServicesResourceGroup']))
	{
		Write-Output "Analysis Services ResourceGroup : $analysisServicesResourceGroup"
		$kVSecretParameters.Add("AnalysisServices--ResourceGroup", $($analysisServicesResourceGroup))
	}
	else
	{
		Write-Output "Analysis Services ResourceGroup: []"
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
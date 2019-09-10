<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		stream.analytics.akv.secrects.ps1

		Purpose:	Set Stream Analytics Secrets Automation Script

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		Set Stream Analytics Key Vault Secrets Automation Script

	.DESCRIPTION
		Set Stream Analytics Key Vault Secrets Automation Script

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Stream Analytics Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER streamAnalyticsName
		Specify the Stream Analytics Name output parameter.

	.PARAMETER streamAnalyticsResourceId
		Specify the Stream Analytics ResourceId output parameter.

	.PARAMETER streamAnalyticsResourceGroup
		Specify the Stream Analytics ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\stream.analytics.akv.secrects.ps1
			-keyVaultName "$(keyVaultName)"
			-streamAnalyticsName "$(streamAnalyticsName)"
			-streamAnalyticsResourceId "$(streamAnalyticsResourceId)"
			-streamAnalyticsResourceGroup "$(streamAnalyticsResourceGroup)"
#>

#Requires -Version 5
#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$streamAnalyticsName,

	[Parameter(Mandatory = $false)]
	[string]$streamAnalyticsResourceId,

	[Parameter(Mandatory = $false)]
	[string]$streamAnalyticsResourceGroup
)

#region - Key Vault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kVSecretParameters = @{ }

	#region - Stream Analytics Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['streamAnalyticsName']))
	{
		Write-Output "Stream Analytics Name: $streamAnalyticsName"
		$kVSecretParameters.Add("StreamAnalytics--Name", $($streamAnalyticsName))
	}
	else
	{
		Write-Output "Stream Analytics Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['streamAnalyticsResourceId']))
	{
		Write-Output "Stream Analytics ResourceId: $streamAnalyticsResourceId"
		$kVSecretParameters.Add("StreamAnalytics--ResourceId", $($streamAnalyticsResourceId))
	}
	else
	{
		Write-Output "Stream Analytics ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['streamAnalyticsResourceGroup']))
	{
		Write-Output "Stream Analytics ResourceGroup: $streamAnalyticsResourceGroup"
		$kVSecretParameters.Add("streamAnalytics--ResourceGroup", $($streamAnalyticsResourceGroup))
	}
	else
	{
		Write-Output "Stream Analytics ResourceGroup: []"
	}
	#endregion

	#region - Set Azure KeyVault Secret
	$kVSecretParameters.Keys | ForEach-Object {
		$key = $psitem
		$value = $kVSecretParameters.Item($psitem)

		if (-not [string]::IsNullOrWhiteSpace($value))
		{
			Write-Output "Key Vault Secret: $key : $value"

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
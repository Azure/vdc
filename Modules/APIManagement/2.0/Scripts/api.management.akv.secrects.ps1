<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		api.management.akv.secrects.ps1

		Purpose:	Set API Management KeyVault Secrets Automation Script

		Version: 	2.0.0.0 - 1st August 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		Set API Management Service KeyVault Secrets Automation Script

	.DESCRIPTION
		Set API Management Service KeyVault Secrets Automation Script

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set API Management Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER apimServiceName
		Specify the API Management Service Name output parameter.

	.PARAMETER apimServiceResourceId
		Specify the API Management Service ResourceId output parameter.

	.PARAMETER apimServiceResourceGroup
		Specify the API Management Service ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\api.management.akv.secrects.ps1
			-keyVaultName "$(keyVaultName)"
			-apimServiceName "$(apimServiceName)"
			-apimServiceResourceId "$(apimServiceResourceId)"
			-apimServiceResourceGroup "$(apimServiceResourceGroup)"
#>

#Requires -Version 5
#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
    [string]$apimServiceName,

    [Parameter(Mandatory = $false)]
    [string]$apimServiceResourceId,

	[Parameter(Mandatory = $false)]
    [string]$apimServiceResourceGroup
)

#region - Key Vault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "Key Vault Name : $keyVaultName"
	$kVSecretParameters = @{ }

	#region - API Management Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['apimServiceName']))
	{
		Write-Output "APIM Service Name : $apimServiceName"
		$kVSecretParameters.Add("APIMService--Name", $($apimServiceName))
	}
	else
	{
		Write-Output "APIM Service Name : []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['apimServiceResourceId']))
	{
		Write-Output "APIM Service ResourceId : $apimServiceResourceId"
		$kVSecretParameters.Add("APIMService--ResourceId", $($apimServiceResourceId))
	}
	else
	{
		Write-Output "APIM Service ResourceId : []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['apimServiceResourceGroup']))
	{
		Write-Output "APIM Service ResourceGroup : $apimServiceResourceGroup"
		$kVSecretParameters.Add("APIMService--ResourceGroup", $($apimServiceResourceGroup))
	}
	else
	{
		Write-Output "APIM Service ResourceGroup : []"
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
				Name        = $key
				SecretValue = (ConvertTo-SecureString $value -AsPlainText -Force)
				Verbose     = $true
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
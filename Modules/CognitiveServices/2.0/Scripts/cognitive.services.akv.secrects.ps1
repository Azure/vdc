<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		cognitive.services.akv.secrects.ps1

		Purpose:	Set Cognitive Services Secrets Automation Script

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		Set Cognitive Services Key Vault Secrets Automation Script

	.DESCRIPTION
		Set Cognitive Services Key Vault Secrets Automation Script

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Cognitive Services Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER cognitiveServicesName
		Specify the Cognitive Services Name output parameter.

	.PARAMETER cognitiveServicesResourceId
		Specify the Cognitive Services ResourceId output parameter.

	.PARAMETER cognitiveServicesResourceGroup
		Specify the Cognitive Services ResourceGroup output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\analysis.services.akv.secrects.ps1
			-keyVaultName "$(keyVaultName)"
			-cognitiveServicesName "$(cognitiveServicesName)"
			-cognitiveServicesResourceId "$(cognitiveServicesResourceId)"
			-cognitiveServicesResourceGroup "$(cognitiveServicesResourceGroup)"
#>

#Requires -Version 5
#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$cognitiveServicesName,

	[Parameter(Mandatory = $false)]
	[string]$cognitiveServicesResourceId,

	[Parameter(Mandatory = $false)]
	[string]$cognitiveServicesResourceGroup
)

#region - Key Vault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kVSecretParameters = @{ }

	#region - Cognitive Services Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['cognitiveServicesName']))
	{
		Write-Output "Cognitive Services Name : $cognitiveServicesName"
		$kVSecretParameters.Add("cognitiveServices--Name", $($cognitiveServicesName))
	}
	else
	{
		Write-Output "Cognitive Services Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['cognitiveServicesResourceId']))
	{
		Write-Output "cognitiveServices ResourceId : $cognitiveServicesResourceId"
		$kVSecretParameters.Add("cognitiveServices--ResourceId", $($cognitiveServicesResourceId))
	}
	else
	{
		Write-Output "Cognitive Services ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['cognitiveServicesResourceGroup']))
	{
		Write-Output "Cognitive Services ResourceGroup : $cognitiveServicesResourceGroup"
		$kVSecretParameters.Add("cognitiveServices--ResourceGroup", $($cognitiveServicesResourceGroup))
	}
	else
	{
		Write-Output "Cognitive Services ResourceGroup: []"
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
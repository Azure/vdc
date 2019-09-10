<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		event.hub.akv.secrects.ps1

		Purpose:	Set EventHub Namespace Secrets Automation Script

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		Set EventHub Namespace Key Vault Secrets Automation Script

	.DESCRIPTION
		Set EventHub Namespace Key Vault Secrets Automation Script

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set EventHub Namespace Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER namespaceName
		Specify the EventHub Namespace Name output parameter.

	.PARAMETER namespaceResourceId
		Specify the EventHub Namespace ResourceId output parameter.

	.PARAMETER namespaceResourceGroup
		Specify the EventHub Namespace ResourceGroup output parameter.

	.PARAMETER namespaceConnectionString
		Specify the EventHub Namespace Connection String output parameter.

	.PARAMETER sharedAccessPolicyPrimaryKey
		Specify the EventHub Namespace Shared Access Policy Primary Key output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\event.hub.akv.secrects.ps1
			-keyVaultName "$(keyVaultName)"
			-namespaceName "$(namespaceName)"
			-namespaceResourceId "$(namespaceResourceId)"
			-namespaceResourceGroup "$(namespaceResourceGroup)"
			-namespaceConnectionString "$(namespaceConnectionString)"
            -sharedAccessPolicyPrimaryKey "$(sharedAccessPolicyPrimaryKey)"
#>

#Requires -Version 5
#Requires -Module Az.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$namespaceName,

	[Parameter(Mandatory = $false)]
	[string]$namespaceResourceId,

	[Parameter(Mandatory = $false)]
	[string]$namespaceResourceGroup,

	[Parameter(Mandatory = $false)]
    [string]$namespaceConnectionString,

    [Parameter(Mandatory = $false)]
    [string]$sharedAccessPolicyPrimaryKey
)

#region - Key Vault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name: $keyVaultName"
	$kVSecretParameters = @{ }

	#region - EventHub Namespace Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['namespaceName']))
	{
		Write-Output "EventHub Namespace Name: $namespaceName"
		$kVSecretParameters.Add("EventHub--namespace--Name", $($namespaceName))
	}
	else
	{
		Write-Output "EventHub Namespace Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['namespaceResourceId']))
	{
		Write-Output "namespace ResourceId: $namespaceResourceId"
		$kVSecretParameters.Add("EventHub--namespace--ResourceId", $($namespaceResourceId))
	}
	else
	{
		Write-Output "EventHub Namespace ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['namespaceResourceGroup']))
	{
		Write-Output "EventHub Namespace ResourceGroup: $namespaceResourceGroup"
		$kVSecretParameters.Add("EventHub--namespace--ResourceGroup", $($namespaceResourceGroup))
	}
	else
	{
		Write-Output "EventHub Namespace ResourceGroup: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['namespaceConnectionString']))
	{
		Write-Output "EventHub Namespace ConnectionString: $namespaceConnectionString"
		$kVSecretParameters.Add("EventHub--namespace--ConnectionString", $($namespaceConnectionString))
	}
	else
	{
		Write-Output "EventHub Namespace ConnectionString: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['sharedAccessPolicyPrimaryKey']))
	{
		Write-Output "EventHub Namespace Shared Access Policy Primary Key: $sharedAccessPolicyPrimaryKey"
		$kVSecretParameters.Add("EventHub--namespace--SharedAccessPolicyPrimaryKey", $($sharedAccessPolicyPrimaryKey))
	}
	else
	{
		Write-Output "EventHub Namespace Shared Access Policy Primary Key: []"
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
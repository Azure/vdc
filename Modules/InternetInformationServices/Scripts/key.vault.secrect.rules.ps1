<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		key.vault.secrect.rules.ps1

		Purpose:	Set Key Vault Secrets Automation Script

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		Set Key Vault Secrets Automation Script

	.DESCRIPTION
		Set Key Vault Secrets Automation Script

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters		
		2) Create Azure KeyVault Secret
			
	.PARAMETER KeyVaultName
		Specify the Azure Key Vault Name parameter.
		
	.EXAMPLE
		Default:
		C:\PS>.\key.vault.secrect.rules.ps1 `
			-KeyVaultName <"KeyVaultName">
#>

#Requires -Version 5
#Requires -Module AzureRM.KeyVault

[CmdletBinding()]
param
( 
	[Parameter(Mandatory = $false)]
	[string]$KeyVaultName
)

#region - Azure KeyVault Parameters
$kVSecretParameters = @{}

if($KeyVaultName -ne $null)
{
	$kVSecretParameters.Add("Secret--KeyVault--Vault", $($KeyVaultName))	
}
else
{
    write-output "Key--KeyVault--Vault: NULL"
}
#endregion

#region - Set Azure KeyVault Secret
$kVSecretParameters.Keys | ForEach-Object {
	$key = $_
	$value = $kVSecretParameters.Item($_) 
	
	$Parameters = @{
		VaultName = $KeyVaultName		
	}	
	if (Get-AzureKeyVaultSecret @Parameters | Where-Object { $psitem.Name -eq "$key" })
	{
		Write-Output "The secret for $key already exists"		
	}
	else
	{
		Write-Output "Setting Secret for $key"
		$Parameters = @{
			VaultName 	= $KeyVaultName
			Name	 	= $key
			SecretValue = (ConvertTo-SecureString $value -AsPlainText -Force)	
		}
		Set-AzureKeyVaultSecret @Parameters	-Verbose
	}
}
#endregion
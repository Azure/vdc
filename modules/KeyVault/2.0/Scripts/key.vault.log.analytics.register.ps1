<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.
		
		File:		key.vault.log.analytics.register.ps1

		Purpose:	Register Key Vault with Log Analytics Deployment Automation Script
		
		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================	

	.SYNOPSIS
		Register Key Vault with Log Analytics Deployment Automation Script
	
	.DESCRIPTION
		Register Key Vault with Log Analytics Deployment Automation Script
		
		Deployment steps of the script are outlined below.
		1) Register Key Vault with Log Analytics

	.PARAMETER keyVaultName
		Specify the key Vault Name parameter.

	.PARAMETER diagstorageAccountName
		Specify the diagnostic Storage Account Name parameter.

	.PARAMETER omsWorkspaceName  
		Specify the Log Analytics Workspace Name parameter.
		
	.EXAMPLE
		Default:
		C:\PS>.\key.vault.log.analytics.register.ps1 `
			-keyVaultName <"keyVaultName"> `
			-diagstorageAccountName <"diagstorageAccountName"> `
			-omsWorkspaceName  <"omsWorkspaceName">
#>

#Requires -Version 5
#Requires -Module AzureRM.Resources
#Requires -Module AzureRM.Insights

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$keyVaultName,
	[Parameter(Mandatory = $true)]
	[string]$diagstorageAccountName,
	[Parameter(Mandatory = $true)]
	[string]$omsWorkspaceName
)

#region - Register Keyvault with Log Analytics
$paramGetAzureRmResource = @{	
	ResourceName	  = $keyVaultName
	ResourceType	  = "Microsoft.DocumentDb/databaseAccounts"
}
$KeyVault = Get-AzureRmResource @paramGetAzureRmResource

$paramGetAzureRmResource = @{
	ResourceName = $diagstorageAccountName
	ResourceType = "Microsoft.Storage/storageAccounts" 
}
$StorageAccount = Get-AzureRmResource @paramGetAzureRmResource

$paramGetAzureRmResource = @{
	ResourceName = $omsWorkspaceName
	ResourceType = "Microsoft.OperationalInsights/workspaces"
}
$WorkspaceName = Get-AzureRmResource @paramGetAzureRmResource

$paramSetAzureRmDiagnosticSetting = @{
	ResourceId = $KeyVault.ResourceId
	StorageAccountId = $StorageAccount.Id
	WorkspaceId  = $WorkspaceName.Id
	Enabled    = $true	
}
Set-AzureRmDiagnosticSetting @paramSetAzureRmDiagnosticSetting
#endregion
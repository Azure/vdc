<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.
		
		File:		cosmosdb.log.analytics.register.ps1

		Purpose:	Register Cosmosdb with Log Analytics Automation Script
		
		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================	

	.SYNOPSIS
		Register Cosmosdb with Log Analytics Automation Script
	
	.DESCRIPTION
		Register Cosmosdb with Log Analytics Automation Script
		
		Deployment steps of the script are outlined below.
		1) Register Cosmosdb with Log Analytics

	.PARAMETER CosmosdbAccountName
		Specify the Cosmosdb Account Name parameter.

	.PARAMETER diagstorageAccountName
		Specify the diagnostic Storage Account Name parameter.

	.PARAMETER omsWorkspaceName  
		Specify the Log Analytics Workspace Name parameter.

	.EXAMPLE
		Default:
		C:\PS>.\cosmosdb.log.analytics.register.ps1 `
			-CosmosdbAccountName <"CosmosdbAccountName"> `
			-diagstorageAccountName <"diagstorageAccountName"> `
			-omsWorkspaceName  <"omsWorkspaceName">
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$CosmosdbAccountName,
	[Parameter(Mandatory = $true)]
	[string]$diagstorageAccountName,
	[Parameter(Mandatory = $true)]
	[string]$omsWorkspaceName
)

#region - Register Cosmosdb with OMS
$paramGetAzureRmResource = @{	
	ResourceName	  = $CosmosdbAccountName
	ResourceType	  = "Microsoft.DocumentDb/databaseAccounts"
}
$Account = Get-AzureRmResource @paramGetAzureRmResource

$paramGetAzureRmResource = @{
	ResourceName = $diagstorageAccountName
	ResourceType = "Microsoft.Storage/storageAccounts"    
}
$StorageAccount = Get-AzureRmResource @$paramGetAzureRmResource

$paramGetAzureRmResource = @{
	ResourceName = $omsWorkspaceName
	ResourceType = "Microsoft.OperationalInsights/workspaces"
}
$WorkspaceName = Get-AzureRmResource @paramGetAzureRmResource

$paramSetAzureRmDiagnosticSetting = @{
	ResourceId = $Account.ResourceId
	StorageAccountId = $StorageAccount.Id
	WorkspaceId  = $WorkspaceName.Id
	Enabled    = $true
	Categories = 'DataPlaneRequests'
}
Set-AzureRmDiagnosticSetting @paramSetAzureRmDiagnosticSetting
#endregion
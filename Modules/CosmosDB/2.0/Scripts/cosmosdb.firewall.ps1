<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.
		
		File:		cosmosdb.firewall.ps1 

		Purpose:	Config Cosmosdb Firewall Automation Script
		
		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================	

	.SYNOPSIS
		Config Cosmosdb Firewall Automation Script
	
	.DESCRIPTION
		Config Cosmosdb Firewall Automation Script
		
		Deployment steps of the script are outlined below.
		1) Config Cosmosdb Firewall

	.PARAMETER CosmosdbAccountName
		Specify the Cosmosdb Firewall Account Name parameter.

	.PARAMETER CosmosdbvNetResourceGroup
		Specify the Cosmosdb Firewall vNet Resource Group parameter.

	.PARAMETER CosmosdbvnetResourceName
		Specify the Cosmosdb Firewall vNet resource Name parameter.

	.PARAMETER CosmosdbsubnetName
		Specify the Cosmosdb Firewall Subnet Name parameter.

	.PARAMETER CosmosdbResourceGroup
		Specify the Cosmosdb Resource Group Name parameter.

	.EXAMPLE
		Default:
		C:\PS>.\cosmosdb.firewall.ps1 `
			-CosmosdbAccountName <"CosmosdbAccountName"> `
			-CosmosdbvNetResourceGroup <"CosmosdbvNetResourceGroup"> `
			-CosmosdbvnetResourceName  <"CosmosdbvnetResourceName"> `
			-CosmosdbsubnetName  <"CosmosdbsubnetName"> `
			-CosmosdbResourceGroup  <"CosmosdbResourceGroup">
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$CosmosdbAccountName,	
	[Parameter(Mandatory = $true)]
	[string]$CosmosdbvNetResourceGroup,
	[Parameter(Mandatory = $true)]
	[string]$CosmosdbvnetResourceName,
	[Parameter(Mandatory = $true)]
	[string]$CosmosdbsubnetName,
	[Parameter(Mandatory = $true)]
	[string]$CosmosdbResourceGroup
)

#region - Config Cosmosdb Firewall
Write-Output "Cosmosdb Account Name: 			$CosmosdbAccountName"
Write-Output "Cosmosdb vNet Resource Group: 	$CosmosdbvNetResourceGroup"
Write-Output "Cosmosdb vnet Resource Name: 		$CosmosdbvnetResourceName"
Write-Output "Cosmosdb Subnet Name:		 		$CosmosdbsubnetName"
Write-Output "Cosmosdb Resource Group Name:		$CosmosdbResourceGroup"

$paramGetAzureRmResource = @{
	ResourceType = "Microsoft.DocumentDB/databaseAccounts" 
	ApiVersion = "2015-04-08"
	ResourceName = $CosmosdbAccountName
	ResourceGroupName = $CosmosdbResourceGroup
}
$CosmosDBConfiguration = Get-AzureRmResource @paramGetAzureRmResource

$paramGetAzureRmVirtualNetwork = @{
    ResourceGroupName = $CosmosdbvNetResourceGroup
    Name = $CosmosdbvnetResourceName 
}
$vnProp = Get-AzureRmVirtualNetwork @paramGetAzureRmVirtualNetwork

$virtualNetworkRules = @(@{
   id = "$($vnProp.Id)/subnets/$CosmosdbsubnetName" 
   ignoreMissingVNetServiceEndpoint = $true  
})

$cosmosDBProperties = @{
    databaseAccountOfferType      = $CosmosDBConfiguration.Properties.databaseAccountOfferType
    consistencyPolicy             = $CosmosDBConfiguration.Properties.consistencyPolicy
    ipRangeFilter                 = "104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26"
    locations                     = $CosmosDBConfiguration.Properties.locations
    virtualNetworkRules           = $virtualNetworkRules
    isVirtualNetworkFilterEnabled = $true 
}

$paramSetAzureRmResource = @{
    ResourceType = "Microsoft.DocumentDb/databaseAccounts"
    ApiVersion = "2015-04-08"
    ResourceGroupName = $CosmosdbResourceGroup
    ResourceName = $CosmosdbAccountName
    Properties = $CosmosDBProperties
}
Set-AzureRmResource @paramSetAzureRmResource -Force
#endregion
<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		cosmosdb.output.test.ps1

		Purpose:	Test - Cosmosdb ARM Template Output Variables

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Cosmosdb ARM template output variables.

	.DESCRIPTION
		This script contains functionality used to test Cosmosdb ARM template output variables.

		Deployment steps of the script are outlined below.
			1) Outputs Variable Logic to pipeline

	.PARAMETER CosmosdbAccountName
		Specify the Cosmosdb Account Name output parameter.

	.PARAMETER CosmosdbEndpoint
		Specify the Cosmosdb Endpoint output parameter.

	.PARAMETER CosmosdbAccountKey
		Specify the Cosmosdb Account Key output parameter.

	.PARAMETER CosmosdbConnectionString
		Specify the Key Cosmosdb Connection String output parameter.

	.PARAMETER CosmosdbTableApiConnectionString
		Specify the Cosmosdb Table Api ConnectionString output parameter.

	.PARAMETER CosmosdbvNetResourceGroup
		Specify the Cosmosdb vNet Resource Group Name output parameter.

	.PARAMETER CosmosdbvnetResourceName
		Specify the Cosmosdb vNet Resource Name output parameter.

	.PARAMETER CosmosdbsubnetName
		Specify the Cosmosdb subnet Name output parameter.

	.PARAMETER CosmosdbResourceGroup
		Specify the Cosmosdb Resource Group Name output parameter.
	
	.EXAMPLE
		Default:
		C:\PS>.\cosmosdb.output.test.ps1 `
			-CosmosdbAccountName <"CosmosdbAccountName"> `
			-CosmosdbEndpoint <"CosmosdbEndpoint"> `
			-CosmosdbAccountKey <"CosmosdbAccountKey"> `
			-CosmosdbConnectionString <"CosmosdbConnectionString"> `
			-CosmosdbTableApiConnectionString <"CosmosdbTableApiConnectionString"> `
			-CosmosdbvNetResourceGroup <"CosmosdbvNetResourceGroup"> `
			-CosmosdbvnetResourceName <"CosmosdbvnetResourceName"> `
			-CosmosdbsubnetName <"CosmosdbsubnetName"> `
			-CosmosdbResourceGroup <"CosmosdbResourceGroup">
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
    [string]$CosmosdbAccountName,
    
    [Parameter(Mandatory = $false)]
    [string]$CosmosdbEndpoint,
    
    [Parameter(Mandatory = $false)]
    [string]$CosmosdbAccountKey,
    
    [Parameter(Mandatory = $false)]
    [string]$CosmosdbConnectionString,

    [Parameter(Mandatory = $false)]
    [string]$CosmosdbTableApiConnectionString,
	
	[Parameter(Mandatory = $false)]
    [string]$CosmosdbvNetResourceGroup,

	[Parameter(Mandatory = $false)]
    [string]$CosmosdbvnetResourceName,

	[Parameter(Mandatory = $false)]
    [string]$CosmosdbsubnetName,

	[Parameter(Mandatory = $false)]
    [string]$CosmosdbResourceGroup
)

if($CosmosdbAccountName -ne $null)
{
    write-output "Cosmosdb Account Name: $($CosmosdbAccountName)"
}
else
{
    write-output "Cosmosdb Account Name: NULL"
}

if($CosmosdbEndpoint -ne $null)
{
    write-output "Cosmosdb Endpoint: $($CosmosdbEndpoint)"
}
else
{
    write-output "Cosmosdb Endpoint: NULL"
}

if($CosmosdbAccountKey -ne $null)
{
    write-output "Cosmosdb Account Key: $($CosmosdbAccountKey)"
}
else
{
    write-output "Cosmosdb Account Key: NULL"
}

if($CosmosdbConnectionString -ne $null)
{
    write-output "Cosmosdb Connection String: $($CosmosdbConnectionString)"
}
else
{
    write-output "Cosmosdb Connection String: NULL"
}

if($CosmosdbTableApiConnectionString -ne $null)
{
    write-output "Cosmosdb Table API Connection String: $($CosmosdbTableApiConnectionString)"
}
else
{
    write-output "Cosmosdb Table API Connection String: NULL"
}

if($CosmosdbvNetResourceGroup -ne $null)
{
    write-output "Cosmosdb Virtual Network Resource Group: $($CosmosdbvNetResourceGroup)"
}
else
{
    write-output "Cosmosdb Virtual Network Resource Group: NULL"
}

if($CosmosdbvnetResourceName -ne $null)
{
    write-output "Cosmosdb Virtual Network Resource Name: $($CosmosdbvnetResourceName)"
}
else
{
    write-output "Cosmosdb Virtual Network Resource Name: NULL"
}

if($CosmosdbsubnetName -ne $null)
{
    write-output "Cosmosdb Virtual Network Subnet Name: $($CosmosdbsubnetName)"
}
else
{
    write-output "Cosmosdb Virtual Network Subnet Name: NULL"
}

if($CosmosdbResourceGroup -ne $null)
{
    write-output "Cosmosdb Resource Group Name: $($CosmosdbResourceGroup)"
}
else
{
    write-output "Cosmosdb Resource Group Name: NULL"
}
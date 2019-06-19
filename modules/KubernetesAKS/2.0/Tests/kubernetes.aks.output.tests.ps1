<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		kubernetes.aks.output.tests.ps1

		Purpose:	Test - Kubernetes Azure Container Service ARM Template Output Variables

		Version: 	1.0.0.0 - 1st May 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Kubernetes Azure Container Service ARM Templates output variables.

	.DESCRIPTION
		This script contains functionality used to test Kubernetes Azure Container Service ARM Templates output variables.

		Deployment steps of the script are outlined below.
            1) Outputs Variable Logic from pipeline

	.PARAMETER nodeResourceGroupId
		Specify the Kubernetes Node Resource Group Id output parameter.

	.PARAMETER nodeResourceGroupName
		Specify the Kubernetes Node Resource Group Name output parameter.

	.PARAMETER aksFQDN
		Specify the Kubernetes Cluster FQDN output parameter.

	.PARAMETER namespaceConnectionString
		Specify the Kubernetes Namespace Connection String output parameter.

	.PARAMETER sharedAccessPolicyPrimaryKey
		Specify the Kubernetes Shared Access Policy Primary Key output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\kubernetes.aks.output.tests.ps1 `
            -nodeResourceGroupId <"nodeResourceGroupId"> `
			-nodeResourceGroupName <"nodeResourceGroupName"> `
			-aksFQDN <"aksFQDN"> `
			-namespaceConnectionString <"namespaceConnectionString"> `
			-sharedAccessPolicyPrimaryKey <"sharedAccessPolicyPrimaryKey">
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
    [string]$nodeResourceGroupId,
	[Parameter(Mandatory = $false)]
    [string]$nodeResourceGroupName,
	[Parameter(Mandatory = $false)]
    [string]$aksFQDN,
	[Parameter(Mandatory = $false)]
    [string]$namespaceConnectionString,
	[Parameter(Mandatory = $false)]
    [string]$sharedAccessPolicyPrimaryKey
)

if($nodeResourceGroupId -ne $null)
{
    write-output "Kubernetes Node Resource Group Id: $($nodeResourceGroupId)"
}
else
{
    write-output "Kubernetes Node Resource Group Id: NULL"
}

if($nodeResourceGroupName -ne $null)
{
    write-output "Kubernetes Node Resource Group Name: $($nodeResourceGroupName)"
}
else
{
    write-output "Kubernetes Node Resource Group Name: NULL"
}

if($aksFQDN -ne $null)
{
    write-output "Kubernetes Cluster FQDN: $($aksFQDN)"
}
else
{
    write-output "Kubernetes Cluster FQDN: NULL"
}

if($namespaceConnectionString -ne $null)
{
    write-output "Kubernetes Namespace Connection String: $($namespaceConnectionString)"
}
else
{
    write-output "Kubernetes Namespace Connection String: NULL"
}

if($sharedAccessPolicyPrimaryKey -ne $null)
{
    write-output "Kubernetes Shared Access Policy Primary Key: $($sharedAccessPolicyPrimaryKey)"
}
else
{
    write-output "Kubernetes Shared Access Policy Primary Key: NULL"
}
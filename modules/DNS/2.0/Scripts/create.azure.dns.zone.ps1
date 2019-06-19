<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		create.azure.dns.zone.ps1
		
		Purpose:	Create Private Azure DNS zone Deployment Automation Script
		
		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================	

	.SYNOPSIS
		Create Private Azure DNS zone Deployment Automation Script
	
	.DESCRIPTION
		Create Private Azure DNS zone Deployment Automation Script
		
		Deployment steps of the script are outlined below.
		1) Creates Azure DNS Zones 
			
	.PARAMETER  vNetResourceGroup
		Specify the vNet Resource Group Name parameter.
	
	.PARAMETER vNetName
		Specify the vNet Name parameter.
	
	.PARAMETER dnsZone
		Specify the dns Zone parameter.
	
	.EXAMPLE
		Default:
		C:\PS>.\create.azure.dns.zone.ps1 `
			-vNetResourceGroup <"vNetResourceGroup"> `
			-vNetName <"vNetName"> `
			-dnsZone <"dnsZone">
#>

#Requires -Version 5
#Requires -Module AzureRM.Dns
#Requires -Module AzureRM.Network

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$vNetResourceGroup,
	[Parameter(Mandatory = $true)]
	[string]$vNetName,
	[Parameter(Mandatory = $false)]
	[string]$dnsZone = "p.azurewebsites.net"
)

#region - Deployment
Write-Output "vNet Resource Group Name:	$vNetResourceGroup"
Write-Output "vNet Name:	$vNetName"
Write-Output "DNS Zone Name:	$dnsZone"

$paramGetAzureRmDnsZone = @{
	Name			  = $dnsZone
	ResourceGroupName = $vNetResourceGroup
	ErrorAction	      = 'SilentlyContinue'
}
if (Get-AzureRmDnsZone @paramGetAzureRmDnsZone)
{
	Write-Output "DNS ZONE $dnsZone already exists - Skipping"
}
else
{
	Write-Output "Creating Private DNS Zone $dnsZone"
	
	$paramGetAzureRmVirtualNetwork = @{
		Name			  = $vNetName
		ResourceGroupName = $vNetResourceGroup
	}
	$vNet = Get-AzureRmVirtualNetwork @paramGetAzureRmVirtualNetwork
	
	$paramNewAzureRmDnsZone = @{
		Name					   = $dnsZone
		ResourceGroupName		   = $vNetResourceGroup
		ZoneType				   = 'Private'
		ResolutionVirtualNetworkId = @($vNet.Id)
	}
	New-AzureRmDnsZone @paramNewAzureRmDnsZone	
}
#endregion
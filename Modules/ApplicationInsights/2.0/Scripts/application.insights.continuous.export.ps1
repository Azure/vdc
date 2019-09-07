<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		application.insights.continuous.export.ps1

		Purpose:	Deploys Application Insights Continuous Export Configuration

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script Deploys Application Insights Continuous Export Configuration

	.DESCRIPTION
		This script Deploys Application Insights Continuous Export Configuration

		Deployment steps of the script are outlined below.
        1) Azure Parameter Configuration
        2) Configure Application Insights Continuous Export

  	.PARAMETER appInsightsName
		Specify the Azure Application Insights Name parameter.

  	.PARAMETER appInsightsStorageAccountName
		Specify the Application Insights Storage Account Name output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\application.insights.continuous.export.ps1
            -appInsightsName "$(appInsightsName)"
            -appInsightsStorageAccountName "$(appInsightsStorageAccountName)"
#>

#Requires -Version 5
#Requires -Module Az.ApplicationInsights
#Requires -Module Az.Storage
#Requires -Module Az.Resources

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$appInsightsName,

	[Parameter(Mandatory = $true)]
	[string]$appInsightsStorageAccountName
)

#region - Application Insights Continuous Export Configuration
Write-Output "Application Insights Name: 					$appInsightsName"
Write-Output "Application Insight Storage Account Name: 	$appInsightsStorageAccountName"

$paramGetAzResource = @{
	ResourceType = "Microsoft.Insights/components"
	ResourceName = $appInsightsName
}
$resource = Get-AzResource @paramGetAzResource
$resourceGroup = $resource.ResourceGroupName

$paramGetAzApplicationInsightsContinuousExport = @{
	ResourceGroupName = $resourceGroup
	Name			  = $appInsightsName
}
$continuousExport = Get-AzApplicationInsightsContinuousExport @paramGetAzApplicationInsightsContinuousExport

if (-not ($continuousExport))
{
	$paramGetAzResource = @{
		ResourceType = "Microsoft.Storage/storageAccounts"
		ResourceName = $appInsightsStorageAccountName
	}
	$resource = Get-AzResource @paramGetAzResource

	$paramGetAzResource = @{
		ResourceId = $resource.Id
	}
	$resource = Get-AzResource @paramGetAzResource

	$paramInvokeAzResourceAction = @{
		Action	   = 'listkeys'
		ResourceId = $resource.ResourceId
		Force	   = $true
	}
	$appInsightsStoragekey = (Invoke-AzResourceAction @paramInvokeAzResourceAction).keys[0].value

	$paramNewAzStorageContext = @{
		StorageAccountName = $appInsightsStorageAccountName
		StorageAccountKey  = $appInsightsStoragekey
	}
	$context = New-AzStorageContext @paramNewAzStorageContext

	$paramNewAzStorageContainer = @{
		Name	   = "appinsights"
		Context    = $context
		Permission = 'Off'
	}
	New-AzStorageContainer @paramNewAzStorageContainer

	$paramNewAzStorageContainerSASToken = @{
		Name	   = "appinsights"
		Context    = $context
		ExpiryTime = (Get-Date).AddYears(50)
		Permission = 'w'
	}
	$sasToken = New-AzStorageContainerSASToken @paramNewAzStorageContainerSASToken
	$sasURI = $resource.Properties.primaryEndpoints.blob + "appinsights" + $sasToken

	$paramNewAzApplicationInsightsContinuousExport = @{
		ResourceGroupName = $ResourceGroup
		Name			  = $appInsightsName
		DocumentType	  = "Request", "Exception", "Custom Event", "Metric", "Page Load", "Page View", "Dependency", "Availability", "Performance Counter"
		StorageAccountId  = $resource.ResourceId
		StorageLocation   = $resource.Properties.primaryLocation
		StorageSASUri	  = $sasURI
		ErrorAction	      = 'Stop'
	}
	New-AzApplicationInsightsContinuousExport @paramNewAzApplicationInsightsContinuousExport
}
else
{
	Write-Output "Skipping - Existing Application Insights Continuous Export Configuration Found"
}
#endregion
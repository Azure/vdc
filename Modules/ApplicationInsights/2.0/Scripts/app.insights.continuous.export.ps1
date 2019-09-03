<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		tier1.appinsights.continuous.export.ps1

		Purpose:	Deploys Application Insights Continuous Export Configuration

		Version: 	1.0.0.3 - 27th August 2019 - Chubb Build Release Deployment Team
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

    .PARAMETER storageAccountName
		Specify the Storage Account Name parameter.

	.EXAMPLE
		Default:
		C:\PS>.\tier1.appinsights.continuous.export.ps1
            -appInsightsName "$(appInsightsName)"
            -storageAccountName "$(storageAccountName)"
#>

#Requires -Version 5
#Requires -Module AzureRM.ApplicationInsights

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$appInsightsName,

	[Parameter(Mandatory = $false)]
	[string]$storageAccountName
)

#region - Application Insights Continuous Export Configuration
Write-Output "Application Insights Name: 	$appInsightsName"
Write-Output "Storage Account Name: 	        $storageAccountName"

$paramGetAzureRmResource = @{
	ResourceType = "Microsoft.Insights/components"
    ResourceName = $appInsightsName
}
$resource = Get-AzureRmResource @paramGetAzureRmResource

$resourceGroup = $resource.ResourceGroupName

$paramGetAzureRmApplicationInsightsContinuousExport = @{
	ResourceGroupName = $resourceGroup
    Name = $appInsightsName
}
$continuousExport = Get-AzureRmApplicationInsightsContinuousExport @paramGetAzureRmApplicationInsightsContinuousExport

if (-not ($continuousExport))
{
	$paramGetAzureRmResource = @{
        ResourceType = "Microsoft.Storage/storageAccounts"
        ResourceName = $storageAccountName
    }
    $resource = Get-AzureRmResource @paramGetAzureRmResource

    $paramGetAzureRmResource = @{
        ResourceId = $resource.Id
    }
    $resource = Get-AzureRmResource @paramGetAzureRmResource

    $ParamInvokeAzureRmResourceAction = @{
	    Action	   = 'listkeys'
	    ResourceId = $resource.ResourceId
    }
    $storageKey = (Invoke-AzureRmResourceAction @ParamInvokeAzureRmResourceAction -Force).keys[0].value

    $paramNewAzureStorageContext =@{
        StorageAccountName  = $storageAccountName
        StorageAccountKey   = $storageKey
    }
    $context = New-AzureStorageContext @paramNewAzureStorageContext

    $paramNewAzureStorageContainer = @{
	    Name	   = "appinsights"
        Context     = $context
	    Permission = 'Off'
    }
    New-AzureStorageContainer @paramNewAzureStorageContainer

    $paramNewAzureStorageContainerSASToken = @{
        Name        = "appinsights"
        Context     = $context
        ExpiryTime  = (Get-Date).AddYears(50)
        Permission  = 'w'
    }
    $sasToken = New-AzureStorageContainerSASToken @paramNewAzureStorageContainerSASToken
    $sasURI = $resource.Properties.primaryEndpoints.blob + "appinsights" + $sasToken

    $paramNewAzureRmApplicationInsightsContinuousExport = @{
        ResourceGroupName   = $resourceGroup
        Name                = $appInsightsName
        DocumentType        = "Request","Exception","Custom Event","Metric","Page Load","Page View","Dependency","Availability","Performance Counter"
        StorageAccountId    = $resource.ResourceId
        StorageLocation     = $resource.Properties.primaryLocation
        StorageSASUri       = $sasURI
        ErrorAction         = 'Stop'
	}
	New-AzureRmApplicationInsightsContinuousExport @paramNewAzureRmApplicationInsightsContinuousExport
}
else
{
	Write-Output "Existing Application Insights Continuous Export Configuration - Skipping"
}
#endregion
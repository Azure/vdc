<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		application.insights.continuousexport.ps1

		Purpose:	Deploys Application Insights Continuous Export Configuration

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script Deploys Application Insights Continuous Export Configuration

	.DESCRIPTION
		This script Deploys Application Insights Continuous Export Configuration

		Deployment steps of the script are outlined below.
        1) Azure Parameter Configuration
        2) Configure Application Insights Continuous Export
		
    .PARAMETER AppInsightName
		Specify the Azure Application Insights Name parameter.

    .PARAMETER StorageAccountName
		Specify the Storage Account Name parameter.

	.EXAMPLE
		Default:
			C:\PS>.\application.insights.continuousexport.ps1 `
				-AppInsightName <"AppInsightName"> `
				-StorageAccountName <"StorageAccountName"> `
#>

#Requires -Version 5
#Requires -Module AzureRM.ApplicationInsights

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$AppInsightName,
	
	[Parameter(Mandatory = $false)]
	[string]$StorageAccountName
)

#region - Application Insights Continuous Export Configuration
Write-Output "Application Insights Name: $AppInsightName"
Write-Output "Storage Account Name: $StorageAccountName"

$Parameters = @{
	ResourceType = "Microsoft.Insights/components"
    ResourceName = $AppInsightName
}
$resource = Get-AzureRmResource @Parameters

$ResourceGroup = $resource.ResourceGroupName

$paramGetAzureRmApplicationInsightsContinuousExport = @{
	ResourceGroupName = $ResourceGroup
    Name = $AppInsightName
}
$ContinuousExport = Get-AzureRmApplicationInsightsContinuousExport @paramGetAzureRmApplicationInsightsContinuousExport

if ($ContinuousExport -ne $null)
{
	Write-Output "Existing Application Insights Continuous Export Configuration - Skipping"
}
else
{
	$Parameters = @{
        ResourceType = "Microsoft.Storage/storageAccounts"
        ResourceName = $StorageAccountName
    }
    $resource = Get-AzureRmResource @Parameters  

    $Parameters = @{
        ResourceId = $resource.Id    
    }
    $resource = Get-AzureRmResource @Parameters
     
    $Parameters = @{
	    Action	   = 'listkeys'
	    ResourceId = $resource.ResourceId   	
    }
    $Storagekey = (Invoke-AzureRmResourceAction @Parameters -Force).keys[0].value
    
    $paramNewAzureStorageContext =@{
        StorageAccountName  = $StorageAccountName
        StorageAccountKey   = $Storagekey
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
    $sastoken = New-AzureStorageContainerSASToken @paramNewAzureStorageContainerSASToken	
    $sasuri = $resource.Properties.primaryEndpoints.blob + "appinsights" + $sastoken

    $paramNewAzureRmApplicationInsightsContinuousExport = @{
        ResourceGroupName   = $ResourceGroup 
        Name                = $AppInsightName
        DocumentType        = "Request","Exception","Custom Event","Metric","Page Load","Page View","Dependency","Availability","Performance Counter"
        StorageAccountId    = $resource.ResourceId 
        StorageLocation     = $resource.Properties.primaryLocation
        StorageSASUri       = $sasuri	
        ErrorAction         = 'Stop'	
	}	
	New-AzureRmApplicationInsightsContinuousExport @paramNewAzureRmApplicationInsightsContinuousExport
}
#endregion
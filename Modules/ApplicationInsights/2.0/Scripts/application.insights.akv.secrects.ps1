<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		Microsoft Consulting Services - AzureCAT - VDC Toolkit (v2.0)

		File:		application.insights.akv.secrects.ps1

		Purpose:	Set Application Insights KeyVault Secrets Automation Script

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		Set Application Insights KeyVault Secrets Automation Script

	.DESCRIPTION
		Set Application Insights KeyVault Secrets Automation Script

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Set Application Insights Parameters
		3) Create Azure KeyVault Secret

	.PARAMETER keyVaultName
		Specify the Azure KeyVault Name parameter.

	.PARAMETER appInsightsName
		Specify the Application Insights Name output parameter.

	.PARAMETER appInsightsResourceId
		Specify the Application Insights Resource Id output parameter.

	.PARAMETER appInsightsResourceGroup
		Specify the Application Insights ResourceGroup output parameter.

	.PARAMETER appInsightsKey
		Specify the Application Insights Instrumentation Key output parameter.

	.PARAMETER appInsightsAppId
		Specify the Application Insights AppId output parameter.

    .PARAMETER appInsightsStorageAccountName
		Specify the Application Storage Account Name output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\application.insights.akv.secrects.ps1
			-keyVaultName "$(keyVaultName)"
            -appInsightsName "$(appInsightsName)"
			-appInsightsResourceId "$(appInsightsResourceId)"
			-appInsightsResourceGroup "$(appInsightsResourceGroup)"
            -appInsightsKey "$(appInsightsKey)"
            -appInsightsAppId "$(appInsightsAppId)"
            -appInsightsStorageAccountName "$(appInsightsStorageAccountName)"
#>

#Requires -Version 5
#Requires -Module Az.KeyVault
#Requires -Module Az.ApplicationInsights
#Requires -Module Az.Resources

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsName,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsResourceId,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsResourceGroup,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsKey,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsAppId,

	[Parameter(Mandatory = $false)]
	[string]$appInsightsStorageAccountName
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name : $keyVaultName"
	$kVSecretParameters = @{ }

	#region - Analysis Services Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsName']))
	{
		Write-Output "Application Insights Name: $appInsightsName"
		$kVSecretParameters.Add("AppInsights--Name", $($appInsightsName))

		#region - Application Insights - ApiKey
		$paramGetAzResource = @{
			ResourceType = "Microsoft.Insights/components"
			ResourceName = $appInsightsName
		}
		$resource = Get-AzResource @paramGetAzResource

		$paramGetAzResource = @{
			ResourceId = $resource.Id
		}
		$resource = Get-AzResource @paramGetAzResource

		$Random = (Get-Random -Minimum 10000 -Maximum 99999)
		$paramNewAzApplicationInsightsApiKey = @{
			ResourceGroupName = $resource.ResourceGroupName
			Name			  = $resource.Name
			Description	      = $resource.Name + "-apikey$Random"
			Permissions	      = @("ReadTelemetry", "WriteAnnotations")
			ErrorAction	      = 'SilentlyContinue'
		}
		$apiInfo = New-AzApplicationInsightsApiKey @paramNewAzApplicationInsightsApiKey
		$apiKey = $apiInfo.ApiKey

		if ( -not [string]::IsNullOrEmpty($apiKey))
		{
			Write-Output "Application Insights apiKey: $apiKey"
			$kVSecretParameters.Add("AppInsights--APIKey", $($apiKey))
		}
		else
		{
			Write-Output "Application Insights apiKey: []"
		}
		#endregion
	}
	else
	{
		Write-Output "Application Insights Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsResourceId']))
	{
		Write-Output "Application Insights ResourceId: $appInsightsResourceId"
		$kVSecretParameters.Add("AppInsights--ResourceId", $($appInsightsResourceId))
	}
	else
	{
		Write-Output "Application Insights ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsResourceGroup']))
	{
		Write-Output "Application Insights ResourceGroup: $appInsightsResourceGroup"
		$kVSecretParameters.Add("AppInsights--ResourceGroup", $($appInsightsResourceGroup))
	}
	else
	{
		Write-Output "Application Insights ResourceGroup: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsKey']))
	{
		Write-Output "Application Insights (OPS) Instrumentation Key: $appInsightsOpsKey"
		$kVSecretParameters.Add("AppInsights--InstrumentationKey", $($appInsightsKey))
	}
	else
	{
		Write-Output "Application Insights Instrumentation Key: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsAppId']))
	{
		Write-Output "Application Insights AppId: $appInsightsAppId"
		$kVSecretParameters.Add("AppInsights--AppId", $($appInsightsAppId))
	}
	else
	{
		Write-Output "Application Insights AppId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsStorageAccountName']))
	{
		Write-Output "Application Insights Storage Account Name $appInsightsStorageAccountName"
		$kVSecretParameters.Add("AppInsights--StorageAccountName", $($appInsightsStorageAccountName))
	}
	else
	{
		Write-Output "Application Insights Storage Account Name []"
	}
	#endregion

	#region - Set Azure KeyVault Secret
	$kVSecretParameters.Keys | ForEach-Object {
		$key = $psitem
		$value = $kVSecretParameters.Item($psitem)

		if (-not [string]::IsNullOrWhiteSpace($value))
		{
			Write-Output "KeyVault Secret: $key : $value"

			$value = $kVSecretParameters.Item($psitem)

			Write-Output "Setting Secret for $key"
			$paramSetAzKeyVaultSecret = @{
				VaultName   = $keyVaultName
				Name	    = $key
				SecretValue = (ConvertTo-SecureString $value -AsPlainText -Force)
				Verbose	    = $true
				ErrorAction = 'SilentlyContinue'
			}
			Set-AzKeyVaultSecret @paramSetAzKeyVaultSecret
		}
		else
		{
			Write-Output "KeyVault Secret: []"
		}
	}
	#endregion
}
else
{
	Write-Output "KeyVault Name: []"
}
#endregion
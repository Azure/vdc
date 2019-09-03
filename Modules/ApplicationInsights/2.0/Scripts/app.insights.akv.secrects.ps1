<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		tier1.app.insights.akv.secrects.ps1

		Purpose:	Set Application Insights KeyVault Secrets Automation Script

		Version: 	1.0.0.1 - 27th August 2019 - Chubb Build Release Deployment Team
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

	.PARAMETER appInsightsOpsName
		Specify the Application Insights (OPS) Name output parameter.

	.PARAMETER appInsightsOpsResourceId
		Specify the Application Insights (OPS) Resource Id output parameter.

	.PARAMETER appInsightsOpsResourceGroup
		Specify the Application Insights (OPS) ResourceGroup output parameter.

	.PARAMETER appInsightsOpsKey
		Specify the Application Insights (OPS) Key output parameter.

	.PARAMETER appInsightsOpsAppId
		Specify the Application Insights (OPS) AppId output parameter.

	.PARAMETER appInsightsRulesName
		Specify the Application Insights (Rules) Name output parameter.

	.PARAMETER appInsightsRulesResourceId
		Specify the Application Insights (Rules) Resource Id output parameter.

	.PARAMETER appInsightsRulesResourceGroup
		Specify the Application Insights (Rules) ResourceGroup output parameter.

	.PARAMETER appInsightsRulesKey
		Specify the Application Insights (Rules) Key output parameter.

	.PARAMETER appInsightsRulesAppId
		Specify the Application Insights (Rules) AppId output parameter.

    .PARAMETER opsStorageAccountName
		Specify the (Ops) Storage Account Name output parameter.

	.PARAMETER rulesStorageAccountName
		Specify the (Rules) Storage Account Name output parameter.

	.EXAMPLE
		Default:
		C:\PS>.\tier1.app.insights.akv.secrects.ps1
			-keyVaultName "$(keyVaultName)"
            -appInsightsOpsName "$(appInsightsOpsName)"
			-appInsightsOpsResourceId "$(appInsightsOpsResourceId)"
			-appInsightsOpsResourceGroup "$(appInsightsOpsResourceGroup)"
            -appInsightsOpsKey "$(appInsightsOpsKey)"
            -appInsightsOpsAppId "$(appInsightsOpsAppId)"
            -appInsightsRulesName "$(appInsightsRulesName)"
			-appInsightsRulesResourceId "$(appInsightsRulesResourceId)"
			-appInsightsRulesResourceGroup "$(appInsightsRulesResourceGroup)"
            -appInsightsRulesKey "$(appInsightsRulesKey)"
            -appInsightsRulesAppId "$(appInsightsRulesAppId)"
            -opsStorageAccountName "$(opsStorageAccountName)"
            -rulesStorageAccountName "$(rulesStorageAccountName)"
#>

#Requires -Version 5
#Requires -Module AzureRM.KeyVault

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$keyVaultName,

	[Parameter(Mandatory = $false)]
    [string]$appInsightsOpsName,

	[Parameter(Mandatory = $false)]
    [string]$appInsightsOpsResourceId,

	[Parameter(Mandatory = $false)]
    [string]$appInsightsOpsResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$appInsightsOpsKey,

    [Parameter(Mandatory = $false)]
    [string]$appInsightsOpsAppId,

    [Parameter(Mandatory = $false)]
    [string]$appInsightsRulesName,

	[Parameter(Mandatory = $false)]
    [string]$appInsightsRulesResourceId,

	[Parameter(Mandatory = $false)]
    [string]$appInsightsRulesResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$appInsightsRulesKey,

    [Parameter(Mandatory = $false)]
    [string]$appInsightsRulesAppId,

    [Parameter(Mandatory = $false)]
    [string]$opsStorageAccountName,

    [Parameter(Mandatory = $false)]
    [string]$rulesStorageAccountName
)

#region - KeyVault Parameters
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['keyVaultName']))
{
	Write-Output "KeyVault Name : $keyVaultName"
	$kVSecretParameters = @{ }

	#region - Analysis Services Parameters
	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsOpsName']))
	{
		Write-Output "Application Insights (OPS) Name: $appInsightsOpsName"
		$kVSecretParameters.Add("AppInsights--OPS--Name", $($appInsightsOpsName))

		#region - OPS Application Insights - ApiKey
		$paramGetAzureRmResource = @{
			ResourceType = "Microsoft.Insights/components"
			ResourceName = $appInsightsOpsName
		}
		$resource = Get-AzureRmResource @paramGetAzureRmResource

		$paramGetAzureRmResource = @{
			ResourceId = $resource.Id
		}
		$resource = Get-AzureRmResource @paramGetAzureRmResource

		$Random = (Get-Random -Minimum 10000 -Maximum 99999)
		$paramNewAzureRmApplicationInsightsApiKey = @{
			ResourceGroupName = $resource.ResourceGroupName
			Name			  = $resource.Name
			Description	      = $resource.Name + "-apikey$Random"
			Permissions	      = @("ReadTelemetry", "WriteAnnotations")
			ErrorAction	      = 'SilentlyContinue'
		}
		$apiInfo = New-AzureRmApplicationInsightsApiKey @paramNewAzureRmApplicationInsightsApiKey
		$apiKey = $apiInfo.ApiKey

		if ($apiKey)
		{
			Write-Output "Application Insights (OPS) apiKey: $apiKey"
			$kVSecretParameters.Add("AppInsights--OPS--APIKey", $($apiKey))
			$kVSecretParameters.Add("Rules--ApplicationInsightsOPS--APIKey", $($apiKey))
		}
		else
		{
			Write-Output "Application Insights (OPS) apiKey: []"
		}
		#endregion
	}
	else
	{
		Write-Output "Application Insights (OPS) Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsOpsResourceId']))
	{
		Write-Output "Application Insights (OPS) ResourceId: $appInsightsOpsResourceId"
		$kVSecretParameters.Add("AppInsights--OPS--ResourceId", $($appInsightsOpsResourceId))
	}
	else
	{
		Write-Output "Application Insights (OPS) ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsOpsResourceGroup']))
	{
		Write-Output "Application Insights (OPS) ResourceGroup: $appInsightsOpsResourceGroup"
		$kVSecretParameters.Add("AppInsights--OPS--ResourceGroup", $($appInsightsOpsResourceGroup))
	}
	else
	{
		Write-Output "Application Insights (OPS) ResourceGroup: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsOpsKey']))
	{
		Write-Output "Application Insights (OPS) Instrumentation Key: $appInsightsOpsKey"
		$kVSecretParameters.Add("AppInsights--OPS--InstrumentationKey", $($appInsightsOpsKey))
		$kVSecretParameters.Add("Rules--ApplicationInsightsOps--InstrumentationKey", $($appInsightsOpsKey))
		$kVSecretParameters.Add("Quotes--ApplicationInsightsOps--InstrumentationKey", $($appInsightsOpsKey))
		$kVSecretParameters.Add("Data--ApplicationInsightsOps--InstrumentationKey", $($appInsightsOpsKey))
		$kVSecretParameters.Add("Rates--ApplicationInsightsOps--InstrumentationKey", $($appInsightsOpsKey))
		$kVSecretParameters.Add("Policy--ApplicationInsightsOps--InstrumentationKey", $($appInsightsOpsKey))
		$kVSecretParameters.Add("CRSPortal--ApplicationInsightsOps--InstrumentationKey", $($appInsightsOpsKey))
	}
	else
	{
		Write-Output "Application Insights (OPS) Instrumentation Key: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsOpsAppId']))
	{
		Write-Output "Application Insights (OPS) AppId: $appInsightsOpsAppId"
		$kVSecretParameters.Add("AppInsights--OPS--AppId", $($appInsightsOpsAppId))
		$kVSecretParameters.Add("Rules--ApplicationInsightsOps--AppId", $($appInsightsOpsAppId))
	}
	else
	{
		Write-Output "Application Insights (OPS) AppId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsRulesName']))
	{
		Write-Output "Application Insights (Rules) Name: $appInsightsRulesName"
		$kVSecretParameters.Add("AppInsights--Rules--Name", $($appInsightsRulesName))

		#region - Rules Application Insights - ApiKey
		$paramGetAzureRmResource = @{
			ResourceType = "Microsoft.Insights/components"
			ResourceName = $appInsightsRulesName
		}
		$resource = Get-AzureRmResource @paramGetAzureRmResource

		$paramGetAzureRmResource = @{
			ResourceId = $resource.Id
		}
		$resource = Get-AzureRmResource @paramGetAzureRmResource

		$Random = (Get-Random -Minimum 10000 -Maximum 99999)
		$paramNewAzureRmApplicationInsightsApiKey = @{
			ResourceGroupName = $resource.ResourceGroupName
			Name			  = $resource.Name
			Description	      = $resource.Name + "-apikey$Random"
			Permissions	      = @("ReadTelemetry", "WriteAnnotations")
			ErrorAction	      = 'SilentlyContinue'
		}
		$apiInfo = New-AzureRmApplicationInsightsApiKey @paramNewAzureRmApplicationInsightsApiKey
		$apiKey = $apiInfo.ApiKey

		if ($apiKey)
		{
			Write-Output "Application Insights (Rules) apiKey: $apiKey"
			$kVSecretParameters.Add("AppInsights--Rules--APIKey", $($apiKey))
			$kVSecretParameters.Add("Rules--ApplicationInsightsRules--APIKey", $($apiKey))
		}
		else
		{
			Write-Output "Application Insights (Rules) apiKey: []"
		}
		#endregion
	}
	else
	{
		Write-Output "Application Insights (Rules) Name: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsRulesResourceId']))
	{
		Write-Output "Application Insights (Rules) ResourceId: $appInsightsRulesResourceId"
		$kVSecretParameters.Add("AppInsights--Rules--ResourceId", $($appInsightsRulesResourceId))
	}
	else
	{
		Write-Output "Application Insights (Rules) ResourceId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsRulesResourceGroup']))
	{
		Write-Output "Application Insights (Rules) ResourceGroup: $appInsightsRulesResourceGroup"
		$kVSecretParameters.Add("AppInsights--Rules--ResourceGroup", $($appInsightsRulesResourceGroup))
	}
	else
	{
		Write-Output "Application Insights (Rules) ResourceGroup: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsRulesKey']))
	{
		Write-Output "Application Insights (Rules) Instrumentation Key: $appInsightsRulesKey"
		$kVSecretParameters.Add("AppInsights--Rules--InstrumentationKey", $($appInsightsRulesKey))
		$kVSecretParameters.Add("Rules--ApplicationInsightsRules--InstrumentationKey", $($appInsightsRulesKey))
		$kVSecretParameters.Add("Quotes--ApplicationInsightsRules--InstrumentationKey", $($appInsightsRulesKey))
		$kVSecretParameters.Add("Data--ApplicationInsightsRule--InstrumentationKey", $($appInsightsRulesKey))
		$kVSecretParameters.Add("Rates--ApplicationInsightsRules--InstrumentationKey", $($appInsightsRulesKey))
		$kVSecretParameters.Add("Policy--ApplicationInsightsRules--InstrumentationKey", $($appInsightsRulesKey))
	}
	else
	{
		Write-Output "Application Insights (Rules) Instrumentation Key: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsRulesAppId']))
	{
		Write-Output "Application Insights (Rules) AppId: $appInsightsRulesAppId"
		$kVSecretParameters.Add("AppInsights--Rules--AppId", $($appInsightsRulesAppId))
		$kVSecretParameters.Add("Rules--ApplicationInsightsRules--AppId", $($appInsightsRulesAppId))
	}
	else
	{
		Write-Output "Application Insights (Rules) AppId: []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['opsStorageAccountName']))
	{
		Write-Output "Application Insights (OPS) Storage Account Name $opsStorageAccountName"
		$kVSecretParameters.Add("AppInsights--OPS--StorageAccountName", $($opsStorageAccountName))
	}
	else
	{
		Write-Output "Application Insights (OPS) Storage Account Name []"
	}

	if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['rulesStorageAccountName']))
	{
		Write-Output "Application Insights (Rules) Storage Account Name : $rulesStorageAccountName"
		$kVSecretParameters.Add("AppInsights--Rules--StorageAccountName", $($rulesStorageAccountName))
	}
	else
	{
		Write-Output "Application Insights (Rules) Storage Account Name: []"
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
			$paramSetAzureKeyVaultSecret = @{
				VaultName   = $keyVaultName
				Name	    = $key
				SecretValue = (ConvertTo-SecureString $value -AsPlainText -Force)
				Verbose	    = $true
				ErrorAction = 'SilentlyContinue'
			}
			Set-AzureKeyVaultSecret @paramSetAzureKeyVaultSecret
		}
		else
		{
			write-output "KeyVault Secret: []"
		}
	}
	#endregion
}
else
{
	write-output "KeyVault Name: []"
}
#endregion
<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		tier1.app.insights.output.tests.ps1

		Purpose:	Test - Application Insights ARM Template Output Variables

		Version: 	1.0.0.4 - 2nd September 2019 - Chubb Build Release Deployment Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Application Insights ARM Templates output variables.

	.DESCRIPTION
		This script contains functionality used to test Application Insights ARM Templates output variables.

		Deployment steps of the script are outlined below.
            1) Outputs variable Logic from pipeline

	.PARAMETER appInsightsOpsName
		Specify the Application Insights (Ops) Name output parameter.

	.PARAMETER appInsightsOpsResourceId
		Specify the Application Insights (Ops) Resource Id output parameter.

	.PARAMETER appInsightsOpsResourceGroup
		Specify the Application Insights (Ops) ResourceGroup output parameter.

	.PARAMETER appInsightsOpsKey
		Specify the Application Insights (Ops) Key output parameter.

	.PARAMETER appInsightsOpsAppId
		Specify the Application Insights (Ops) AppId output parameter.

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
		C:\PS>.\tier1.app.insights.output.tests.ps1
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

[CmdletBinding()]
param
(
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

#region - Application Insights (Ops)

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsOpsName']))
{
    Write-Output "Application Insights (OPS) Name: $($appInsightsOpsName)"
}
else
{
    Write-Output "Application Insights (OPS) Name: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsOpsResourceId']))
{
    Write-Output "Application Insights (OPS) ResourceId: $($appInsightsOpsResourceId)"
}
else
{
    Write-Output "Application Insights (OPS) Resource Id: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsOpsResourceGroup']))
{
    Write-Output "Application Insights (OPS) ResourceGroup: $($appInsightsOpsResourceGroup)"
}
else
{
    Write-Output "Application Insights (OPS) ResourceGroup: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsOpsKey']))
{
    Write-Output "Application Insights (OPS) Instrumentation Key: $($appInsightsOpsKey)"
}
else
{
    Write-Output "Application Insights (OPS) Instrumentation Key: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsOpsAppId']))
{
    Write-Output "Application Insights (OPS) AppId: $($appInsightsOpsAppId)"
}
else
{
    Write-Output "Application Insights (OPS) AppId: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['opsStorageAccountName']))
{
    Write-Output "Application Insights (Ops) Storage Account Name: $($opsStorageAccountName)"
}
else
{
    Write-Output "Application Insights (Ops) Storage Account Name: []"
}
#endregion

#region - Application Insights (Rules)
if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsRulesName']))
{
    Write-Output "Application Insights (Rules) Name: $($appInsightsRulesName)"
}
else
{
    Write-Output "Application Insights (Rules) Name: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsRulesResourceId']))
{
    Write-Output "Application Insights (Rules) ResourceId: $($appInsightsRulesResourceId)"
}
else
{
    Write-Output "Application Insights (Rules) Resource Id: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsRulesResourceGroup']))
{
    Write-Output "Application Insights (Rules) ResourceGroup: $($appInsightsRulesResourceGroup)"
}
else
{
    Write-Output "Application Insights (Rules) ResourceGroup: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsRulesKey']))
{
    Write-Output "Application Insights (Rules) Instrumentation Key: $($appInsightsRulesKey)"
}
else
{
    Write-Output "Application Insights (Rules) Instrumentation Key: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['appInsightsRulesAppId']))
{
    Write-Output "Application Insights (Rules) AppId: $($appInsightsRulesAppId)"
}
else
{
    Write-Output "Application Insights (Rules) AppId: []"
}

if (-not [string]::IsNullOrWhiteSpace($PSBoundParameters['rulesStorageAccountName']))
{
    Write-Output "Application Insights (Rules) Storage Account Name: $($rulesStorageAccountName)"
}
else
{
    Write-Output "Application Insights (Rules) Storage Account Name: []"
}
#endregion
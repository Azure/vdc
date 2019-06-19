<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		application.insights.output.test.ps1

		Purpose:	Test - Application Insight ARM Template Output Variables

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Application Insight ARM Template Output Variables.

	.DESCRIPTION
		This script contains functionality used to test Application Insight ARM Template Output Variables.

		Deployment steps of the script are outlined below.
            1) Outputs Variable Logic from pipeline

	.PARAMETER AppInsightName
		Specify the Application Insight Name output parameter.

	.PARAMETER AppInsightKey
		Specify the Application Insight Key output parameter.

	.PARAMETER AppInsightAppId
		Specify the Application Insight AppId output parameter.
		
    .PARAMETER StorageAccountName
		Specify the Storage Account Name output parameter.
			
	.EXAMPLE
		Default:
		C:\PS>.\application.insights.output.test.ps1 `
            -AppInsightName <"AppInsightName"> `
            -AppInsightKey <"AppInsightKey"> `
            -AppInsightAppId <"AppInsightAppId"> `
            -StorageAccountName <"StorageAccountName"> 		
#>

#Requires -Version 5

[CmdletBinding()]
param
(
    [Parameter(Mandatory = $false)]
    [string]$AppInsightName,

    [Parameter(Mandatory = $false)]
    [string]$AppInsightKey,

    [Parameter(Mandatory = $false)]
    [string]$AppInsightAppId,
    
    [Parameter(Mandatory = $false)]
    [string]$StorageAccountName
)

#region - AppInsight
if($AppInsightName -ne $null)
{
    write-output "Application Insights Name: $($AppInsightName)"
}
else
{
    write-output "Application Insights Name: NULL"
}

if($AppInsightKey -ne $null)
{
    write-output "Application Insights Instrumentation Key: $($AppInsightKey)"
}
else
{
    write-output "Application Insights Instrumentation Key: NULL"
}

if($AppInsightAppId -ne $null)
{
    write-output "Application Insights AppId: $($AppInsightAppId)"
}
else
{
    write-output "Application Insights AppId: NULL"
}

if($StorageAccountName -ne $null)
{
    write-output "Application Insights Storage Account Name: $($StorageAccountName)"
}
else
{
    write-output "Application Insights Storage Account Name: NULL"
}
#endregion

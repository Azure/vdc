<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		InstallDependencies.ps1

		Purpose:	PowerShell - Install Module Dependencies

		Version: 	2.0.0.0 - 1st September 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to install PowerShell Module Dependencies.

	.DESCRIPTION
		This script contains functionality used to install PowerShell Module Dependencies.

		Deployment steps of the script are outlined below.
        1) Install Az Module
		2) Install Az.ResourceGraph Module
		3) Install Pester Module

		DISCLAIMER:
		==============================================================================================
		This script is not supported under any Microsoft standard support program or service.
		
		This script is provided AS IS without warranty of any kind.
		Microsoft further disclaims all implied warranties including, without limitation, any
		implied warranties of merchantability or of fitness for a particular purpose.
		
		The entire risk arising out of the use or performance of the script
		and documentation remains with you. In no event shall Microsoft, its authors,
		or anyone else involved in the creation, production, or delivery of the
		script be liable for any damages whatsoever (including, without limitation,
		damages for loss of business profits, business interruption, loss of business
		information, or other pecuniary loss) arising out of the use of or inability
		to use the sample scripts or documentation, even if Microsoft has been
		advised of the possibility of such damages.
		==============================================================================================
#>

#Requires -Version 5

#region - Functions
function Get-IsElevated
{
	#region - Get-IsElevated()
	try
	{
		$WindowsId = [System.Security.Principal.WindowsIdentity]::GetCurrent()
		$WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($WindowsId)
		$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
		
		if ($WindowsPrincipal.IsInRole($adminRole))
		{
			return $true
		}
		else
		{
			return $false
		}
	}
	catch [system.exception]
	{
		Write-Output "Error in Get-IsElevated() $($psitem.Exception.Message) Line:$($psitem.InvocationInfo.ScriptLineNumber) Char:$($psitem.InvocationInfo.OffsetInLine)"
		exit
	}
	#endregion
}
#endregion

#region - Install Dependencies
Clear-Host

Write-Output "Script Started"

if (Get-IsElevated)
{
	try
	{
		$timeSync = Get-Date
		$timeSync = $timeSync.ToString()
		
		Write-Output "Script is running in an elevated PowerShell host."
		Write-Output "Start time: $timeSync`n"
		
		#region - Install PowerShell Modules
		$paramInstallModule = @{
			Name = 'Az', 'Az.ResourceGraph', 'Pester'
			Force = $true
			ErrorAction = 'Stop'
		}
		Install-Module @paramInstallModule
		#endregion
		
		$timeSync = Get-Date
		$timeSync = $timeSync.ToString()
		Write-Output "`nEnded at: $timeSync"
	}
	catch [system.exception]
	{
		Write-Output "Error:$($psitem.Exception.Message) Line:$($psitem.InvocationInfo.ScriptLineNumber) Char:$($psitem.InvocationInfo.OffsetInLine)"
		exit
	}
}
else
{
	Write-Output "Please start the script from an elevated PowerShell host."
	exit
}

Write-Output "Script Completed."
#endregion
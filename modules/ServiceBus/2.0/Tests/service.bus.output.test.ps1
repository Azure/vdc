<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		service.bus.output.test.ps1

		Purpose:	Test - Service Bus ARM Template Output Variables

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script contains functionality used to test Service Bus ARM template output variables.

	.DESCRIPTION
		This script contains functionality used to test Service Bus ARM template output variables.

		Deployment steps of the script are outlined below.
			1) Outputs Variable Logic to pipeline

	.PARAMETER ServiceBusConnectionString
		Specify the Service Bus Connection String output parameter.

	.PARAMETER ServiceBusPrimaryKey
		Specify the Service Bus Primary Key output parameter.

	.PARAMETER ServiceBusSendListenConnectionString
		Specify the Service Bus Send Listen Connection String output parameter.

	.PARAMETER ServiceBusSendListenPrimaryKey
		Specify the Service Bus Send Listen Primary Key output parameter.
	
	.EXAMPLE
		Default:
		C:\PS>.\service.bus.output.test.ps1 `
			-ServiceBusConnectionString <"ServiceBusConnectionString"> ` 
			-ServiceBusPrimaryKey <"ServiceBusPrimaryKey"> `
			-ServiceBusSendListenConnectionString <"ServiceBusSendListenConnectionString">
			-ServiceBusSendListenPrimaryKey <"ServiceBusSendListenPrimaryKey">
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
    [string]$ServiceBusConnectionString,    
    [Parameter(Mandatory = $false)]
    [string]$ServiceBusPrimaryKey,
	[Parameter(Mandatory = $false)]
    [string]$ServiceBusSendListenConnectionString,    
    [Parameter(Mandatory = $false)]
    [string]$ServiceBusSendListenPrimaryKey
)

if($ServiceBusConnectionString -ne $null)
{
    write-output "Azure ServiceBus Connection String: $($ServiceBusConnectionString)"
}
else
{
    write-output "Azure ServiceBus Connection String: NULL"
}

if($ServiceBusPrimaryKey -ne $null)
{
    write-output "Azure ServiceBus Primary Key: $($ServiceBusPrimaryKey)"
}
else
{
    write-output "Azure ServiceBus Primary Key: NULL"
}

if($ServiceBusSendListenConnectionString -ne $null)
{
    write-output "Azure ServiceBus Send Listen Connection String: $($ServiceBusSendListenConnectionString)"
}
else
{
    write-output "Azure ServiceBus Send Listen Connection String: NULL"
}

if($ServiceBusSendListenPrimaryKey -ne $null)
{
    write-output "Azure ServiceBus Send Listen Primary Key: $($ServiceBusSendListenPrimaryKey)"
}
else
{
    write-output "Azure ServiceBus Send Listen Primary Key: NULL"
}
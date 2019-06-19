<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		cosmosdb.provision.ruleset.collection.ps1

		Purpose:	Configures Cosmosdb Provision RuleSet Collection

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script configures CosmosDb Provision RuleSet Collection

	.DESCRIPTION
		This script configures CosmosDb Provision RuleSet Collection

		Deployment steps of the script are outlined below.
        1) Import Cosmosdb PowerShell Module
        2) Azure Parameter Configuration
		3) Cosmosdb Database creation if required
		4) Cosmosdb Collection Configuration

    .PARAMETER AzureSearchName
    Specify the Azure Search Name parameter.

    .PARAMETER CosmosdbAccountName
    Specify the Cosmosdb Account Name parameter.

    .PARAMETER CosmosdbAccountKey
    Specify the Cosmosdb Account Key parameter.

    .PARAMETER CosmosdbName
    Specify the Cosmosdb Database Name parameter.

    .PARAMETER CosmosdbContainerName
	Specify the Cosmosdb Container Name parameter.

	.PARAMETER CosmosdbResourceGroup
	Specify the Cosmosdb Resource Group Name parameter.

	.EXAMPLE
		Default:
		C:\PS>.\cosmosdb.provisionrulesetcollection.ps1 `
			-CosmosdbAccountName <"CosmosdbAccountName"> `
			-CosmosdbAccountKey <"CosmosdbAccountKey"> `
			-CosmosdbName  <"CosmosdbName"> `
			-CosmosdbContainerName  <"CosmosdbContainerName"> `
			-CosmosdbResourceGroup <"CosmosdbResourceGroup">
#>

#Requires -Version 5

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $false)]
	[string]$CosmosdbAccountName,
	[Parameter(Mandatory = $false)]
	[string]$CosmosdbAccountKey,
	[Parameter(Mandatory = $false)]
	[string]$CosmosdbName = "RuleEngine",
	[Parameter(Mandatory = $false)]
	[string]$CosmosdbContainerName = "quote",
	[Parameter(Mandatory = $false)]
	[string]$CosmosdbResourceGroup
)

#region - Import CosmosDB PowerShell Module
Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
Install-Module -Name CosmosDB -RequiredVersion 2.1.15.239 -Force -Verbose -Scope CurrentUser
#endregion

#region - Azure Parameter Configuration
Write-Output "Cosmosdb Account Name: 			$CosmosdbAccountName"
Write-Output "Cosmosdb Account Key: 			$CosmosdbAccountKey"
Write-Output "Cosmosdb Database Name: 			$CosmosdbName"
Write-Output "Cosmosdb Container Name:			$CosmosdbContainerName"
Write-Output "Cosmosdb Resource Group Name:		$CosmosdbResourceGroup"

$CosmosdbPartitionKeyPath = "Identifier"

$paramNewCosmosDbContext = @{
	Account  = $CosmosdbAccountName
	Database = $CosmosdbName
	ResourceGroupName = $CosmosdbResourceGroup	
    MasterKeyType = 'PrimaryMasterKey'		
}
$CosmosDbContext = New-CosmosDbContext @paramNewCosmosDbContext
Write-Output "DEBUG New-CosmosDbContext"

try 
{
	$paramGetCosmosDbDatabase = @{
		Context	    = $CosmosDbContext
		Id	    	= $CosmosdbName			
	}
	$CosmosDb = Get-CosmosDbDatabase @paramGetCosmosDbDatabase
	Write-Output "DEBUG Get-CosmosDbDatabase"
}
catch
{
	if ($CosmosDb -ne $null)
    {
	    Write-Output "Existing Cosmosdb database: $CosmosdbName - Skipping"
    }
    else
    {
	    Write-Output "Creating New Cosmosdb database: $CosmosdbName"

	    $paramNewCosmosDbDatabase = @{
		    Context	    = $CosmosDbContext
            Id	    	= $CosmosdbName        
        }	
	    New-CosmosDbDatabase @paramNewCosmosDbDatabase    
	    Write-Output "DEBUG New-CosmosDbDatabase"
    }
}
#endregion

#region - CosmosDB Collection Configuration
try 
{
	$paramGetCosmosDbCollection = @{
		Context	    = $CosmosDbContext
		Id		    = $CosmosdbContainerName		
	}
	$CosmosDbCollection = Get-CosmosDbCollection @paramGetCosmosDbCollection
	Write-Output "DEBUG Get-CosmosDbCollection"
}
catch 
{
	if ($CosmosDbCollection -ne $null)
	{
		Write-Output "CosmosDB Collection Configuration already exists - Skipping"
	}
	else
	{
		Write-Output "Performing CosmosDB Collection Configuration"

		$paramNewCosmosDbCollectionIncludedPathIndex = @{
			Kind	  = 'Hash'
			DataType  = 'String'
			Precision = 3
		}
		$indexStringHash = New-CosmosDbCollectionIncludedPathIndex @paramNewCosmosDbCollectionIncludedPathIndex
	
		$paramNewCosmosDbCollectionIncludedPathIndex = @{
			Kind	  = 'Range'
			DataType  = 'Number'
			Precision = -1
		}
		$indexNumberRange = New-CosmosDbCollectionIncludedPathIndex @paramNewCosmosDbCollectionIncludedPathIndex
	
		$paramNewCosmosDbCollectionIncludedPathIndex = @{
			Kind	 = 'Spatial'
			DataType = 'Point'
		}
		$indexNumberSpatial = New-CosmosDbCollectionIncludedPathIndex @paramNewCosmosDbCollectionIncludedPathIndex
	
		$paramNewCosmosDbCollectionIncludedPath = @{
			Path  = '/*'
			Index = $indexStringHash, $indexNumberRange, $indexNumberSpatial
		}
		$indexIncludedPathAll = New-CosmosDbCollectionIncludedPath @paramNewCosmosDbCollectionIncludedPath
		
		$paramNewCosmosDbCollectionIncludedPath = @{
			Path  = '/Version/?'
			Index = $indexNumberRange
		}
		$indexIncludedPathVersion = New-CosmosDbCollectionIncludedPath @paramNewCosmosDbCollectionIncludedPath
		
		$paramNewCosmosDbCollectionIncludedPath = @{
			Path  = '/ApplicableDateUtcEpoch/?'
			Index = $indexNumberRange
		}
		$indexIncludedPathApplicableDateUtcEpoch = New-CosmosDbCollectionIncludedPath @paramNewCosmosDbCollectionIncludedPath
	
		$paramNewCosmosDbCollectionIndexingPolicy = @{
			Automatic    = $true
			IndexingMode = 'Consistent'
			IncludedPath = $indexIncludedPathAll, $indexIncludedPathVersion, $indexIncludedPathApplicableDateUtcEpoch
		}
		$indexingPolicy = New-CosmosDbCollectionIndexingPolicy @paramNewCosmosDbCollectionIndexingPolicy
	
		$paramNewCosmosDbCollection = @{
			Context		    = $CosmosDbContext
			Id			    = $CosmosdbContainerName
			PartitionKey    = $CosmosdbPartitionKeyPath
			IndexingPolicy  = $indexingPolicy
			OfferThroughput = 10000
		}
		New-CosmosDbCollection @paramNewCosmosDbCollection
	}
}
#endregion
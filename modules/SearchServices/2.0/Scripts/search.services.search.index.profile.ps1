<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		search.services.search.index.profile.ps1

		Purpose:	Configures Azure Search Index Profiles in a Comosdb Account

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		This script configures Azure Search Index Profile

	.DESCRIPTION
		This script configures Azure Search Index Profile

		Deployment steps of the script are outlined below.
        1) Azure Search Service Parameters
        2) Create the API Headers
        3) Invoke API Calls into Azure Search

    .PARAMETER AzureSearchName
		Specify the Azure Search Name parameter.

    .PARAMETER AzureSearchResourceGroup
		Specify the Azure Search Resource Group Name parameter.

    .PARAMETER CosmosdbAccountName
		Specify the Cosmosdb Account Name parameter.

    .PARAMETER CosmosdbAccountKey
		Specify the Cosmosdb Account Key parameter.

    .PARAMETER CosmosdbName
		Specify the Comosdb Database Name parameter.

    .PARAMETER CosmosdbContainerName
		Specify the Comosdb Database Container Name parameter.

	.EXAMPLE
		Default:
		C:\PS>.\search.services.search.index.profile.ps1 `
			-AzureSearchName <"AzureSearchName"> `
			-AzureSearchResourceGroup <"AzureSearchResourceGroup"> `
			-CosmosdbAccountName <"CosmosdbAccountName"> `
			-CosmosdbAccountKey <"CosmosdbAccountKey"> `
			-CosmosdbName <"CosmosdbName">
			-CosmosdbContainerName <"CosmosdbContainerName">
#>

#Requires -Version 5
#Requires -Module AzureRM.Resources

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
    [string]$AzureSearchName,
    [Parameter(Mandatory = $true)]
    [string]$AzureSearchResourceGroup,    
	[Parameter(Mandatory = $true)]
	[string]$CosmosdbAccountName,
	[Parameter(Mandatory = $true)]
	[string]$CosmosdbAccountKey,
	[Parameter(Mandatory = $false)]
	[string]$CosmosdbName = "RuleEngine",
	[Parameter(Mandatory = $false)]
	[string]$CosmosdbContainerName = "quote"
)

#region - Parameter Configuration
Write-Output "Azure Search Service Name: 	$AzureSearchName"
Write-Output "Azure Search Resource Group: 	$AzureSearchResourceGroup"
Write-Output "Cosmosdb Account Name: 		$CosmosdbAccountName"
Write-Output "Cosmosdb Account Key: 		$CosmosdbAccountKey"
Write-Output "Cosmosdb Database Name:		$CosmosdbName"
Write-Output "Cosmosdb Container Name: 		$CosmosdbContainerName"

$Parameters = @{
    ResourceType = "Microsoft.Search/searchServices"
    ResourceGroup = $AzureSearchResourceGroup
    Name = "$AzureSearchName"
}
$resource = Get-AzureRmResource @Parameters

$Parameters = @{
	Action	   = 'listAdminKeys'
	ResourceId = $resource.ResourceId
	ApiVersion = '2015-08-19'
}
$AzureSearchApiKey = (Invoke-AzureRmResourceAction @Parameters -Force).PrimaryKey
#endregion

#region - API Parameters
$datasourceName = "rulesets-$($CosmosdbContainerName.ToLower())-data-source"
$targetIndexName = "rulesets-$($CosmosdbContainerName.ToLower())-index"
$indexerName = "rulesets-$($CosmosdbContainerName.ToLower())-indexer"

Write-Output "rulesets datasource name:	$datasourceName"
Write-Output "rulesets index namee:		$targetIndexName"
Write-Output "rulesets indexer name: 	$indexerName"

$headers = @{
	'cache-control'=  'no-cache'
	'Content-Type'  = 'application/json'
	'api-key' = "$($AzureSearchApiKey)"
}

$createDataSourceRequest = @"
{
    "name": "$($datasourceName)",
    "type": "documentdb",
    "credentials": {
        "connectionString": "AccountEndpoint=https://$($CosmosdbAccountName).documents.azure.com;AccountKey=$($CosmosdbAccountKey);Database=$($CosmosdbName)"
    },
    "container": {
        "name": "$($CosmosdbContainerName)",
        "query": null
    },
    "dataChangeDetectionPolicy": {
        "@odata.type": "#Microsoft.Azure.Search.HighWaterMarkChangeDetectionPolicy",
        "highWaterMarkColumnName": "_ts"
    }
}
"@;

$createIndexRequest = @"
	 {
        name: '$($targetIndexName)',
        fields:
        [
            {
                name: 'Identifier',
                type: 'Edm.String',
                retrievable: true,
                sortable: true,
                searchable: true,
                filterable: true,
                facetable: true
            },
            {
                name: 'Version',
                type: 'Edm.Int64',
                searchable: false,
                retrievable: true,
                sortable: true,
                filterable: true,
                facetable: false
            },
            {
                name: 'Description',
                type: 'Edm.String',
                searchable: true,
                retrievable: true,
                sortable: false,
                filterable: false,
                facetable: false
            },
            {
                name: 'Active',
                type: 'Edm.Boolean',
                searchable: false,
                retrievable: true,
                sortable: false,
                filterable: true,
                facetable: false
            },
            {
                name: 'IsPublished',
                type: 'Edm.Boolean',
                searchable: false,
                retrievable: true,
                sortable: false,
                filterable: true,
                facetable: false
            },
            {
                name: 'Pipeline',
                type: 'Collection(Edm.String)',
                searchable: true,
                retrievable: true,
                filterable: false,
                sortable: false,
                facetable: false
            },
            {
                name: 'ApplicableDateUtc',
                type: 'Edm.DateTimeOffset',
                retrievable: true,
                filterable: true,
                searchable: false,
                sortable: true,
                facetable: false
            },
            {
                name: 'CreatedAtUtc',
                type: 'Edm.DateTimeOffset',
                retrievable: true,
                filterable: true,
                searchable: false,
                sortable: true,
                facetable: false
            },
            {
                name: 'UpdatedAtUtc',
                type: 'Edm.DateTimeOffset',
                retrievable: true,
                filterable: true,
                searchable: false,
                sortable: true,
                facetable: false
            },
            {
                name: 'rid',
                key: true,
                type: 'Edm.String',
                retrievable: true,
                filterable: true,
                searchable: true,
                sortable: false,
                facetable: false
            }
        ]
    }
"@;

$createIndexerRequest = @"
    {
        name: '$($indexerName)',
        dataSourceName: '$($datasourceName)',
        targetIndexName: '$($targetIndexName)',
        schedule: { interval: 'PT5M' }
    }
"@;
#endregion

#region - REST API
$paramInvokeRestMethod = @{
	Uri = "https://$($AzureSearchName).search.windows.net/datasources/$($datasourceName)?api-version=2017-11-11"
	Method = 'PUT'
	Body = $createDataSourceRequest
	Headers = $headers
    ContentType = "application/json"
    Verbose	    = $true
	ErrorAction = 'Stop'
}
Invoke-RestMethod @paramInvokeRestMethod

$paramInvokeRestMethod = @{
	Uri = "https://$($AzureSearchName).search.windows.net/indexes/$($targetIndexName)?api-version=2017-11-11"
	Method = 'PUT'
	Body = $createIndexRequest
	Headers = $headers
    ContentType = "application/json"
    Verbose	    = $true
	ErrorAction = 'Stop'
}
Invoke-RestMethod @paramInvokeRestMethod

$paramInvokeRestMethod = @{
	Uri = "https://$($AzureSearchName).search.windows.net/indexers/$($indexerName)?api-version=2017-11-11"
	Method = 'PUT'
	Body = $createIndexerRequest
	Headers = $headers
    ContentType = "application/json"
    Verbose	    = $true
	ErrorAction = 'Stop'
}
Invoke-RestMethod @paramInvokeRestMethod

$paramInvokeRestMethod = @{
	Uri = "https://$($AzureSearchName).search.windows.net/indexers/$($indexerName)/run?api-version=2017-11-11"
	Method = 'POST'
    Headers = $headers
    Verbose	    = $true
	ErrorAction = 'Stop'
}
Invoke-RestMethod @paramInvokeRestMethod
#endregion
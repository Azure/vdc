########################################################################################################################
##
## CacheDataService.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the CacheDataService Module using Pester.
##          The script will import the CacheDataService Module and any dependency moduels to perform the tests.
##
########################################################################################################################
$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "RepositoryService", "Interface", "ICacheRepository.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "RepositoryService", "Implementations", "AzureDevOpsCacheRepository.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "RepositoryService", "Implementations", "LocalCacheRepository.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "DataService", "Interface", "ICacheDataService.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "DataService", "Implementations", "CacheDataService.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

Describe  "Cache Data Service Unit Test Cases" {

    Context "Cache Data Service using Azure DevOps Cache Repository" {
        BeforeEach {
            $azureDevOpsRepository = New-Object AzureDevOpsCacheRepository;
            $cacheDataService = New-Object CacheDataService -ArgumentList $azureDevOpsRepository;
            $cacheKey = 'SASKEY';
            $cacheValue = 'erltowhtgf88934n34iruf348jkn34843fnv74';
            $Env:VDC_CACHE_SASKEY = $cacheValue;
        }

        It "Should set cache by key and value" {
            
            $cacheDataService.SetByKey($cacheKey, $cacheValue);
            $cacheData = $cacheDataService.GetByKey("sas-key");
            $cacheData | Should Be $cacheValue;
        }

        It "Should retreive cache data by valid key" {
            $cacheKey = 'vdc.cache.sas-key';
            $cacheData = $cacheDataService.GetByKey("sas-key");
            $cacheData | Should Not Be $null;
        }

        It "Should return null when attempting to retreive cache data by invalid key" {
            $cacheKey = 'vdc.cache.invalid-key';
            $cacheData = $cacheDataService.GetByKey("invalid-key");
            $cacheData | Should Be $null;
        }
    }

    Context "Cache Data Service using Local Cache Repository" {
        BeforeEach {
            $azureDevOpsRepository = New-Object LocalCacheRepository;
            $cacheDataService = New-Object CacheDataService -ArgumentList $azureDevOpsRepository;
            $cacheKey = 'vdc.cache.sas-key';
            $cacheValue = 'erltowhtgf88934n34iruf348jkn34843fnv74';
        }

        It "Should set cache by key and value" {
            
            $cacheDataService.SetByKey($cacheKey, $cacheValue);
            $cacheData = $cacheDataService.GetByKey($cacheKey);
            $cacheData | Should Be $cacheValue;
        }

        It "Should retreive cache data by valid key" {
            $cacheData = $cacheDataService.GetByKey($cacheKey);
            $cacheData | Should Not Be $null;
        }

        It "Should return null when attempting to retreive cache data by invalid key" {
            $cacheKey = 'vdc.cache.invalid-key';
            $cacheData = $cacheDataService.GetByKey($cacheKey);
            $cacheData | Should Be $null;
        }

        It "Should remove cache data by key" {
            $cacheDataService.RemoveByKey($cacheKey);
            $cacheData = $cacheDataService.GetByKey($cacheKey);
            $cacheData | Should Be $null;
        }

        It "Should retreive all cache data" {
            $cacheDataService.SetByKey("dummy-cache-key-1", "dummy-cache-value-1");
            $cacheDataService.SetByKey("dummy-cache-key-2", "dummy-cache-value-2");
            $cacheDataService.SetByKey("dummy-cache-key-3", "dummy-cache-value-3");
            $cacheDataService.SetByKey("dummy-cache-key-4", "dummy-cache-value-4");
            $cacheDataService.SetByKey("dummy-cache-key-5", "dummy-cache-value-5");
            $allCacheItems = $cacheDataService.GetAll();
            $allCacheItems.Count | Should Be 5;
        }

        It "Should remove all cache data when flush is called" {
            $cacheDataService.Flush();
            $allCacheItems = $cacheDataService.GetAll();
            $allCacheItems.Count | Should Be 0;
        }
        
    }
}
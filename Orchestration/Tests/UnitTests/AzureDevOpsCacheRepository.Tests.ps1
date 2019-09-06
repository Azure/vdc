########################################################################################################################
##
## AzureDevOpsCacheRepository.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the AzureDevOpsCacheRepository Module using Pester.
##          The script will import the AzureDevOpsCacheRepository Module and any dependency moduels to perform the tests.
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
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "Common", "Helper.psd1");
Import-Module $scriptPath -Force

Describe  "Azure DevOps Cache Repository Unit Test Cases" {

    Context "Azure DevOps Cache" {
        BeforeEach {
            
            $storageAccountName = "vdc-storage-account"
            $storageResourceGroupName = "do-storage-rg"
            $Env:VDC_CACHE_TESTS_STORAGEACCOUNTNAME = $storageAccountName;
            $Env:VDC_CACHE_TESTS_STORAGERESOURCEGROUPNAME = $storageResourceGroupName;

            $azureDevOpsCacheRepository = `
                New-Object AzureDevOpsCacheRepository;
        }
        It "Should save the value to cache" {
            $cacheValue1 = $azureDevOpsCacheRepository.GetByKey('tests_storageAccountName');
            $cacheValue1 | Should Be $storageAccountName;

            $cacheValue2 = $azureDevOpsCacheRepository.GetByKey('tests_storageResourceGroupName');
            $cacheValue2 | Should Be $storageResourceGroupName;
        }

        It "Should get the cache by key" {
            { $azureDevOpsCacheRepository.Set('storageBlobContainer', 'true') } | Should Not Throw "Failed";
        }

        It "Should get all cache given a prefix" {
            $caches = $azureDevOpsCacheRepository.GetAll();
            $caches.Count | Should BeGreaterThan 0;
        }
    }
}
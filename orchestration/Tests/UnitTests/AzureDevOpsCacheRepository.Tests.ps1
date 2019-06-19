########################################################################################################################
##
## AzureDevOpsCacheRepository.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the AzureDevOpsCacheRepository Module using Pester.
##          The script will import the AzureDevOpsCacheRepository Module and any dependency moduels to perform the tests.
##
########################################################################################################################
. ../../RepositoryService/Interface/ICacheRepository.ps1;
. ../../RepositoryService/Implementations/AzureDevOpsCacheRepository.ps1;

Describe  "Azure DevOps Cache Repository Unit Test Cases" {

    Context "Azure DevOps Cache" {
        BeforeEach {
            
            $storageAccountName = "vdc-storage-account"
            $storageResourceGroupName = "do-storage-rg"
            $Env:vdc_tests_storageAccountName = $storageAccountName;
            $Env:vdc_tests_storageResourceGroupName = $storageResourceGroupName;

            $azureDevOpsCacheRepository = `
                New-Object AzureDevOpsCacheRepository;
        }
        It "Should save the value to cache" {
            $cache = $azureDevOpsCacheRepository.GetByKey('vdc_tests_storageAccountName');
            $cache | Should Be $storageAccountName;
        }

        It "Should get the cache by key" {
            { $azureDevOpsCacheRepository.Set('vdc_tests_storageBlobContainer', 'true') } | Should Not Throw "Failed";
        }

        It "Should get all cache given a prefix" {
            $caches = $azureDevOpsCacheRepository.GetAll("vdc_tests");
            $caches.Count | Should Be 2;
        }
    }
}
########################################################################################################################
##
## localCacheRepository.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the localCacheRepository Module using Pester.
##          The script will import the localCacheRepository Module and any dependency moduels to perform the tests.
##
########################################################################################################################
. ../../RepositoryService/Interface/ICacheRepository.ps1;
. ../../RepositoryService/Implementations/LocalCacheRepository.ps1;

Describe  "Azure DevOps Cache Repository Unit Test Cases" {

    Context "Local Cache Repository" {
        BeforeEach {
            $dummyValue = "contoso-storage";
            $localCacheRepository = `
                New-Object LocalCacheRepository;
        }
        It "Should set the value to cache" {
            $localCacheRepository.Set('vdc_tests_dummy1', $dummyValue);
            $cache = $localCacheRepository.GetByKey('vdc_tests_dummy1');
            $cache | Should Be $dummyValue;
        }

        It "Should get the value from cache" {
            $cache = $localCacheRepository.GetByKey('vdc_tests_dummy1');
            $cache | Should Be $dummyValue;
        }

        It "Should get all cache given a prefix" {
            $localCacheRepository.Set('vdc_tests_dummy2', $dummyValue);
            $localCacheRepository.Set('vdc_tests_dummy3', $dummyValue);
            $localCacheRepository.Set('vdc_tests_dummy4', $dummyValue);
            $localCacheRepository.Set('vdc_tests_dummy5', $dummyValue);
            $localCacheRepository.Set('vdc_tests_dummy6', $dummyValue);
            $localCacheRepository.Set('vdc_tests_dummy7', $dummyValue);

            $cacheItems = $localCacheRepository.GetAll();
            $cacheItems.Count | Should Be 7;
        }

        It "Should remove cache item by key" {
            $localCacheRepository.RemoveByKey('vdc_tests_dummy2');

            $cache = $localCacheRepository.GetByKey('vdc_tests_dummy2');
            $cache | Should Be "";
        }
 
        It "Should flush all cache items" {
            $localCacheRepository.Flush();
            $cacheItems = $localCacheRepository.GetAll();
            $cacheItems.Count | Should Be 0;
        }
    }
}
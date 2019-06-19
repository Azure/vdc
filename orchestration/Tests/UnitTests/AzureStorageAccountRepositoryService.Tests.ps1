########################################################################################################################
##
## DeploymentAuditDataService.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the AuditDataService Module using Pester.
##          The scrip will import the AuditDataService Module and any dependencty modules to perform the tests.
##
########################################################################################################################

using Module './../../RepositoryService/Interface/IRepositoryService.psd1';
using Module './../../RepositoryService/Implementations/AzureStorageAccountRepositoryService.psd1';


$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe  "Azure Storage Account Repository Service Unit Test Cases" {

    Context "Save Operation" {
        BeforeEach {
            $configuration = [PSCustomObject]@{
                "ResourceGroupName" = "do-ss-storage-account-rg"
                "StorageAccountName" = "do-ss-storage-account"
            }
            $azureStorageAccountRepositoryService = New-Object AzureStorageAccountRepositoryService -ArgumentList $configuration;
        }

        It "Should persist data to the repository" {
            $key = "shared-services-wus2/diagnostics-storage-account/release-id-1/deployment-id";
            $data = [PSCustomObject]@{};
            $azureStorageAccountRepositoryService.Save($key, $data);
            $retreivedData = $azureStorageAccountRepositoryService.Get($key);
            $retreivedData | Should Be $data;
        }
    }

    Context "Get Operation" {
        BeforeEach {
            $azStorageRepositoryService = New-Object AzureStorageAccountRepositoryService;
            $data = [PSCustomObject]@{};
        }

        It "Should retreive data from the repository" {
            $key = "shared-services-wus2/diagnostics-storage-account/release-id-1/deployment-id";
            $retreivedData = $azureStorageAccountRepositoryService.Get($key);
            $retreivedData | Should Be $data;
        }
    }

    Context "Update Operation" {
        BeforeEach {
            $azStorageRepositoryService = New-Object AzureStorageAccountRepositoryService;
        }

        It "Should update data in the repository" {
            $key = "shared-services-wus2/diagnostics-storage-account/release-id-1/deployment-id";
            $data = [PSCustomObject]@{};
            $azureStorageAccountRepositoryService.Update($key, $data);
            $retreivedData = $azureStorageAccountRepositoryService.Get($key);
            $retreivedData | Should Be $data;
        }
    }

    Context "Delete Operation" {
        BeforeEach {
            $azStorageRepositoryService = New-Object AzureStorageAccountRepositoryService;
        }

        It "Should remove data from the repository" {
            $key = "shared-services-wus2/diagnostics-storage-account/release-id-1/deployment-id";
            $azureStorageAccountRepositoryService.Delete($key);
            $retreivedData = $azureStorageAccountRepositoryService.Get($key);
            $retreivedData | Should Be $null;
        }
    }
}
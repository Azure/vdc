########################################################################################################################
##
## BlobContainerAuditRepository.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the BlobContainerAuditRepository Module using Pester.
##          The script will import the BlobContainerAuditRepository Module and any dependency moduels to perform the tests.
##
########################################################################################################################
. ../../RepositoryService/Interface/IAuditRepository.ps1;
. ../../RepositoryService/Implementations/BlobContainerAuditRepository.ps1;

Describe  "Blob Container Audit Repository Unit Test Cases" {

    Context "Blob Container Audit" {
        BeforeEach {
            $storageAccountName = "vdcstorageaccount";
            $storageAccountSasToken= "?fj8mjfdojg89j4k3489tndhwd8n4398nf";
            Mock New-AzStorageContext {
                return (New-MockObject -Type Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext)
            }
            Mock Set-AzStorageblobcontent {
                return (Test-Path -Path $File);
            }
            Mock Get-AzStorageblobcontent {
                return "demo-file";
            }
            $blobContainerAuditRepository = `
                New-Object BlobContainerAuditRepository($storageAccountName, $storageAccountSasToken);
        }
        It "Should invoke the Set-AzStorageblobcontent for SaveResourceState" {
            $entity = [PSCustomObject]@{
                "ArchetypeInstanceName" = "contoso-shared-services"
                "auditId" = "f02bf00b-2bc7-4ad0-91b2-8d43df923907"
            };
            $blobContainerAuditRepository.SaveAuditTrail($entity);
            Assert-MockCalled Set-AzStorageblobcontent -Times 1 -Exactly;
        }

        It "Should invoke the Get-AzStorageBlobContent for GetAuditTrailById" {
            $archetypeInstanceName = "contoso-shared-services"
            $auditId = "f02bf00b-2bc7-4ad0-91b2-8d43df923907"
            $blobContainerAuditRepository.GetAuditTrailById($archetypeInstanceName, $auditId);
            Assert-MockCalled Get-AzStorageblobcontent -Times 1 -Exactly;
        }
    }
}
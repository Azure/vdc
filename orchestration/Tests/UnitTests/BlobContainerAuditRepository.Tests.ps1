########################################################################################################################
##
## BlobContainerAuditRepository.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the BlobContainerAuditRepository Module using Pester.
##          The script will import the BlobContainerAuditRepository Module and any dependency moduels to perform the tests.
##
########################################################################################################################
$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "RepositoryService", "Interface", "IAuditRepository.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "RepositoryService", "Implementations", "BlobContainerAuditRepository.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

Describe  "Blob Container Audit Repository Unit Test Cases" {

    Context "Blob Container Audit" {
        BeforeEach {
            $storageAccountName = "vdcstorageaccount";
            $storageAccountSasToken= "?fj8mjfdojg89j4k3489tndhwd8n4398nf";
            $blobContent = ConvertTo-Json (@{ foo = "bar"});
            Mock New-AzStorageContext {
                return (New-MockObject -Type Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext)
            }
            Mock Set-AzStorageblobcontent {
                return (Test-Path -Path $File);
            }
            Mock Get-AzStorageblobcontent {
                return $blobContent;
            }
            Mock Get-Content {
                return $blobContent;
            }

            $blobContainerAuditRepository = `
                New-Object BlobContainerAuditRepository(
                    $storageAccountName, 
                    $storageAccountSasToken);
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
            $filters = @($archetypeInstanceName, $auditId);
            $blobContainerAuditRepository.GetAuditTrailByFilters($filters);
            Assert-MockCalled Get-AzStorageblobcontent -Times 1 -Exactly;
        }
    }
}
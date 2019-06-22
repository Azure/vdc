########################################################################################################################
##
## BlobContainerStateRepository.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the BlobContainerStateRepository Module using Pester.
##          The script will import the BlobContainerStateRepository Module and any dependency moduels to perform the tests.
##
########################################################################################################################
$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "RepositoryService", "Interface", "IStateRepository.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "RepositoryService", "Implementations", "BlobContainerStateRepository.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

Describe  "Blob Container State Repository Unit Test Cases" {

    Context "Blob Container State" {
        BeforeEach {
            $storageAccountName = "vdcstorageaccount";
            $storageAccountSasToken= "?fj8mjfdojg89j4k3489tndhwd8n4398nf";
            Mock New-AzStorageContext {
                return (New-MockObject -Type Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext)
            }
            Mock Set-AzStorageblobcontent {
                return (Test-Path -Path $File);
            }
            $blobContainerStateRepository = `
                New-Object BlobContainerStateRepository($storageAccountName, $storageAccountSasToken);
        }
        It "Should invoke the Set-AzStorageblobcontent for SaveResourceState" {
            $entity = [PSCustomObject]@{
                "DeploymentId" = "demofile"
            };
            $blobContainerStateRepository.SaveResourceState($entity);
            Assert-MockCalled Set-AzStorageblobcontent -Times 1 -Exactly;
        }

        It "Should invoke the Set-AzStorageblobcontent for SaveResourceStateAndDeploymentIdMapping" {
            $entity = [PSCustomObject]@{
                "DeploymentId" = "demofile"
            };
            $blobContainerStateRepository.SaveResourceState($entity);
            Assert-MockCalled Set-AzStorageblobcontent -Times 2 -Exactly;
        }

        It "Should check for blob existence given container and blob name" {
            
        }
    }
}
########################################################################################################################
##
## DeploymentAuditDataService.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the AuditDataService Module using Pester.
##          The scrip will import the AuditDataService Module and any dependencty modules to perform the tests.
##
########################################################################################################################
$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "RepositoryService", "Interface", "IAuditRepository.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "RepositoryService", "Implementations", "LocalStorageAuditRepository.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "DataService", "Interface", "IDeploymentAuditDataService.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$scriptPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath  @("..", "DataService", "Implementations", "DeploymentAuditDataService.ps1");
$scriptBlock = ". $scriptPath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

Describe  "Audit Data Service Unit Test Cases" {

    Context "Save audit trail" {
        BeforeEach {
            $localAuditRepository = `
                New-Object LocalStorageAuditRepository;
            $auditDataService = [DeploymentAuditDataService]::new($localAuditRepository);
        }

        It "Should save the audit data" {

            $auditId = $auditDataService.SaveAuditTrail('BuildId',
                                                        'BuildName',
                                                        (New-Guid).Guid,
                                                        'Commit Message',
                                                        'Commit Username',
                                                        'BuildQueuedBy',
                                                        'ReleaseId',
                                                        'ReleaseName',
                                                        'ReleaseRequestedFor',
                                                        (New-Guid).Guid,
                                                        (New-Guid).Guid,
                                                        @{},
                                                        'ArchetypeInstanceName');
            $auditId| Should Not Be $null;
        }
    }

    Context "Get audit trail" {
        BeforeEach {
            $localAuditRepository = `
                New-Object LocalStorageAuditRepository;
            $auditDataService = [DeploymentAuditDataService]::new($localAuditRepository);
        }
    }
}
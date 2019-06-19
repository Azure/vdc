########################################################################################################################
##
## DeploymentAuditDataService.Tests.ps1
##
##          The purpose of this script is to perform the unit testing for the AuditDataService Module using Pester.
##          The scrip will import the AuditDataService Module and any dependencty modules to perform the tests.
##
########################################################################################################################

. ../../DataService/Interface/IDeploymentAuditDataService.ps1;
. ../../DataService/Implementations/DeploymentAuditDataService.ps1;


$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe  "Audit Data Service Unit Test Cases" {

    Context "Save audit trail" {
        BeforeEach {
            $auditDataService = New-Object AuditDataService;
        }

        It "Should save the audit data" {
            $auditId = $auditDataService.SaveAuditTrail((New-Guid).Guid, `
                                                        'Mock Build Name', `
                                                        (New-Guid).Guid, `
                                                        (New-Guid).Guid, `
                                                        (New-Guid).Guid, `
                                                        (New-Guid).Guid, `
                                                        'Mock-Shared-Services');
            $auditTrail = $auditDataService.GetResourceStateById($auditId);
            $auditTrail.AuditId | Should Be $auditId;
        }
    }

    Context "Get audit trail" {
        BeforeEach {
            $auditDataService = New-Object AuditDataService;
        }

        It "Should get audit trail by audit id" {
            $auditId = (New-Guid).Guid;
            $auditTrail = $auditDataService.GetAuditTrailById($auditId);
            $auditTrail.AuditId | Should Be $auditId;
        }

        It "Should get audit trail by build id" {
            $buildId = (New-Guid).Guid;
            $auditDataService.GetAuditTrailByBuildId($buildId);
            $auditTrail[0].BuildId | Should Be $buildId;
        }

        It "Should get audit trail by commit id" {
            $commitId = (New-Guid).Guid;
            $auditDataService.GetAuditTrailByCommitId($commitId);
            $auditTrail[0].CommitId | Should Be $commitId;
        }

        It "Should get audit trail by user id" {
            $userId = (New-Guid).Guid;
            $auditDataService.GetAuditTraiByUserId($userId);
            $auditTrail[0].UserId | Should Be $userId;
        }
    }
}
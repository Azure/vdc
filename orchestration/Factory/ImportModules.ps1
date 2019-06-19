$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'RepositoryService') -ChildPath 'Interface') -ChildPath 'IStateRepository.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'RepositoryService') -ChildPath 'Implementations') -ChildPath 'BlobContainerStateRepository.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'RepositoryService') -ChildPath 'Interface') -ChildPath 'IAuditRepository.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'RepositoryService') -ChildPath 'Implementations') -ChildPath 'BlobContainerAuditRepository.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'RepositoryService') -ChildPath 'Implementations') -ChildPath 'LocalStorageStateRepository.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'RepositoryService') -ChildPath 'Implementations') -ChildPath 'LocalStorageAuditRepository.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'RepositoryService') -ChildPath 'Interface') -ChildPath 'ICacheRepository.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'RepositoryService') -ChildPath 'Implementations') -ChildPath 'AzureDevOpsCacheRepository.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'RepositoryService') -ChildPath 'Implementations') -ChildPath 'LocalCacheRepository.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'DataService') -ChildPath 'Interface') -ChildPath 'IModuleStateDataService.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'DataService') -ChildPath 'Implementations') -ChildPath 'ModuleStateDataService.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'DataService') -ChildPath 'Interface') -ChildPath 'IDeploymentAuditDataService.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'DataService') -ChildPath 'Implementations') -ChildPath 'DeploymentAuditDataService.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'DataService') -ChildPath 'Interface') -ChildPath 'ICacheDataService.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'DataService') -ChildPath 'Implementations') -ChildPath 'CacheDataService.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'IntegrationService') -ChildPath 'Interface') -ChildPath 'IDeploymentService.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;
$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'IntegrationService') -ChildPath 'Implementations') -ChildPath 'AzureResourceManagerDeploymentService.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'TokenReplacementService') -ChildPath 'Interface') -ChildPath 'ITokenReplacementService.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$modulePath = Join-Path (Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'TokenReplacementService') -ChildPath 'Implementations') -ChildPath 'TokenReplacementService.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

$modulePath = Join-Path (Join-Path (Join-Path $rootPath -ChildPath '..') -ChildPath 'OrchestrationService') -ChildPath 'ArchetypeInstanceBuilder.ps1'
$scriptBlock = ". $modulePath";
$script = [scriptblock]::Create($scriptBlock);
. $script;

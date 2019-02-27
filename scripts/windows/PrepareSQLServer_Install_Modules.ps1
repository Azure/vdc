Install-PackageProvider -Name NuGet -Force -Confirm:$false
$all_modules = @("xStorage", "PSDesiredStateConfiguration", "xSmbShare", "xComputerManagement", "xNetworking", "xActiveDirectory", "xFailoverCluster", "SqlServer", "SqlServerDsc")
For ($i=0; $i -lt $all_modules.Length; $i++){
    $module_found = Get-Module -FullyQualifiedName $all_modules[$i] -ListAvailable
    if ($module_found -eq $null){
        if ($all_modules[$i] -eq "SqlServer"){
            Install-Module -Name $all_modules[$i] -Force -Confirm:$false -AllowClobber
        }
        else{
            Install-Module -Name $all_modules[$i] -Force -Confirm:$false
        }
    }
}
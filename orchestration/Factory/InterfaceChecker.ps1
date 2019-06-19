<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		InterfaceChecker.ps1

        Purpose:	Interface Class Implementation with check for methods on Concrete Classes that 
                    inherit from the "Interface" Class

		Version: 	1.0.0.0 - 1st May 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
        This script enforces the methods in the Interface classes to be implemented in the 
        Concrete Class that inherit from the Interface Class.

	.DESCRIPTION
        This script enfirces the methods in the Interface classes to be implemented in the 
        Concrete Class that inherit from the Interface Class. PowerShell does not support Interfaces. 
        As part of the logic, the scripts perform the steps below:
        1. Imports all the "Interface" classes  and then concrete using "Using Module". This will be 
        required because the Using Module statement with ScriptBlock cannot be used inside individual 
        modules. (Scriptblock allows us to use variables inside the Using Module statement which is 
        otherwise not possible).
        2. Get all Manifest Paths for Modules other than the Interface Modules.
        3. For Each Manifest Paths:
            a. Load the Module from Manifest
            b. Check if the module contains classes
            c. If yes, Check if the class inherit
            d. If yes, compare the methods in the "Interface" and Concrete classes to ensure all
            the methods are implemented. If one or more methods are not implemented, throw an exception

#>

#Requires -Version 6;

#-----------------------------------------------------------[Variables]------------------------------------------------------------

$rootPath = "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)/../../";
$fileNameParserRegEx = '(?:[\/\\]Interface[\/\\][\d\w\.]+)';

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Enum ManifestType {
    Interface
    NonInterface
    All
}

Function GetAllModuleManifestPaths() {
    <#
    .SYNOPSIS
        Returns all the Module Manifests
    .DESCRIPTION
        Returns all the Module Manifests under a given directory.
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [ManifestType]$ManifestType
    )
    $allModuleManifestPaths = (Get-ChildItem $rootPath -Filter "*.psd1" -Recurse).FullName;
    if($ManifestType -eq [ManifestType]::All) {
        return $allModuleManifestPaths;
    }
    elseif($ManifestType -eq [ManifestType]::Interface) {
        return ($allModuleManifestPaths | Where-Object { $_ -match $fileNameParserRegEx });
    }
    elseif($ManifestType -eq [ManifestType]::NonInterface) {
        return ($allModuleManifestPaths | Where-Object { $_ -notmatch $fileNameParserRegEx });
    }
}

Function ImportAllInterfaces() {
    <#
    .SYNOPSIS
        Loads the "interface" class modules
    .DESCRIPTION
        Loads the "interface" class modules that are required before their concrete class modules
        are loaded. To identify the interface class modules from concrete class modules, we use
        the folder structure because of the chicken-egg situation (i.e, we need to inspect 
        the concrete class module to get the interface but concrete class module need interface class
        moduels to be loaded before we inspect the concrete class modules). 
    #>
    $interfaceModuleManifests = GetAllModuleManifestPaths -ManifestType ([ManifestType]::Interface);
    # Works for both Mac and Windows Path types
    # Makes sure the file is under the Interface folder
    
    forEach($moduleManifest in $interfaceModuleManifests) {
        if($moduleManifest -notlike '*Factory.psd1') {
            Write-Verbose ("Loading Interface Module {0}" -f $moduleManifest);
            Import-ModuleUsingPath -ManifestPath $moduleManifest;
        }
    }
    Write-Host "Completed loading all Modules";
}

Function GetModuleFromManifestPath() {
    <#
    .SYNOPSIS
        Gets the Module from Manifest Path
    .DESCRIPTION
        Retreives the module form the Manifest Path. The Module needs to be 
        imported. Then use Test-ModuleManifest to retreive the manifest (to
        retreive the module name)  and finally use the module name to get the
        module to be returned.
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ManifestPath
    )
    # Needs to be imported first before using Get-Module
    Import-ModuleUsingPath -ManifestPath $ManifestPath;
    # Needs this to retreive the Module Name from the manifest object
    $moduleManifest = Test-ModuleManifest -Path $ManifestPath;
    # Finally get the module from module name and return
    return (Get-Module $moduleManifest.Name);
}

Function CheckIfModuleContainsClass() {
    <#
    .SYNOPSIS
        Checks if the module contains Classes
    .DESCRIPTION
        Checks if the module contains Classes. Classes are exposed as DefinedTypes.
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [object]$Module
    )
    if($Module.ImplementingAssembly.DefinedTypes.Count -gt 0) {
        return $true;
    }
    else {
        return $false;
    }
}

Function CheckIfClassImplementsInterface() {
    <#
    .SYNOPSIS
        Checks if the Class Implements an "Interface" Class
    .DESCRIPTION
        Checks if the Class Implements an "Interface" Class. This is done by inspecting
        the immediate BaseType of the Class. All Classes in PowerShell inherit from 
        System.Object directly or indirectly. Classes that Inherit from other classes have
        an immediate BaseType of the inheriting Class instead of System.Object.
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [object]$Class
    )
    if($Class.BaseType -eq [System.Object]) {
        return $false;
    }
    else {
        return $true;
    }
}

Function CheckForUnImplementedMethods() {
    <#
    .SYNOPSIS
        Checks for Unimplemented Methods in Concrete Class given an "Interface" Class
    .DESCRIPTION
        Checks for Unimplemented Methods in Concrete Class given an "Interface" Class.
        This is done by iterating the methods in the "Interface" class and checking the 
        concrete class for those method implementation.
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [object] $ConcreteClass,
        [Parameter(Mandatory=$false)]
        [object] $InterfaceClass
    )
    $methodsInConcreteClass = $ConcreteClass.DeclaredMethods.Name | Sort-Object Name;
    $methodsInInterfaceClass = $InterfaceClass.DeclaredMethods.Name | Sort-Object Name;
    forEach($method in $methodsInInterfaceClass) {
        if($methodsInConcreteClass -notcontains $method) {
            Throw ("Method {0} missing in Concrete Class {1} that implements Interface Class {2}" -f $method, $ConcreteClass.Name.ToString(), $ConcreteClass.BaseType.ToString());
        }
    }
}

Function CheckModuleForClassesWithInterfaces() {
    <#
    .SYNOPSIS
        For a given Module Manifest, check if the manifest 
    .DESCRIPTION
        The Write-Host cmdlet customizes output. You can specify the color of text by using
        the ForegroundColor parameter, and you can specify the background color by using the
        BackgroundColor parameter. The Separator parameter lets you specify a string to use to
        separate displayed objects. The particular result depends on the program that is
        hosting Windows PowerShell.
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ManifestPath
    )
    $concreteClassModule = GetModuleFromManifestPath -ManifestPath $ManifestPath;
    if($concreteClassModule -ne $null `
        -and (CheckIfModuleContainsClass -Module $concreteClassModule)) {
        $definedTypesInConcreteClass = $concreteClassModule.ImplementingAssembly.DefinedTypes;
        forEach($concreteClass in $definedTypesInConcreteClass) {
            # By default, all PowerShell Classes inherit from System.Object. BaseType property of a 
            # class reflects the inheritance for a Class. 
            # * Classes that do not inherit (explicitly), have a BaseType of System.Object. 
            # * Classes that inherit explicitly from other Classes have a BaseType of their inheriting Class.
            if(CheckIfClassImplementsInterface -Class $concreteClass) {
                $interfaceClassModule = Get-Module $concreteClass.BaseType;
                $definedTypesInInterfaceClass = $interfaceClassModule.ImplementingAssembly.DefinedTypes;
                CheckForUnImplementedMethods -ConcreteClass $concreteClass -InterfaceClass $definedTypesInInterfaceClass;
            }
        }
    }
}

Function Import-ModuleUsingPath() {
    <#
    .SYNOPSIS
        Imports the Module using Path
    .DESCRIPTION
        Imports the Module using Path
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ManifestPath
    )
    # We do not want the module trying to import itself.
    # If Factory module tries to import Factory module, 
    # it creates an infinite loop.
    if($ManifestPath -notlike "*Factory.psd1" `
        -and $ManifestPath -notmatch $fileNameParserRegEx) {
        Write-Host "Loading - $ManifestPath";
        #Import-Module $ManifestPath -Force;
    }
}

Function Execute() {
    <#
    .SYNOPSIS
        Executes the logic to enforce methods implemented in Concrete Class based on
        methods from their Interface Class 
    .DESCRIPTION
        Executes the logic to enforce methods implemented in Concrete Class based on
        methods from their Interface Class
    #>
    # Import all the interfaces first before inspecting the manifests of the concrete classes
    # because the concrete class's modules needs to be loaded after the "interface" class's
    # modules.
    ImportAllInterfaces;

    # Import Path to all Module Manifests
    $manifestPaths = GetAllModuleManifestPaths -ManifestType ([ManifestType]::NonInterface);

    # Iterate them and check the module for "interface" implementation
    # If "interfaces" are implemented, compare them to enforce 
    # implementation of the methods in the "interface" class with that 
    # of the concrete class that implement the "interface" class
    forEach($manifestPath in $manifestPaths) {
        CheckModuleForClassesWithInterfaces -ManifestPath $manifestPath;
    }
}

#-----------------------------------------------------------[Main Statements]------------------------------------------------------------

# "Using Module" will be used to load all the modules along with their Classes
# "Using Module" does not accept variables in its Module Path. Also it has to 
# be the first statement in a script / module file.
# Due to these restrictions, ScriptBlock is used to load all the modules first.
$scriptBlock = "";
# First iteration will import all Interface Modules
GetAllModuleManifestPaths -ManifestType ([ManifestType]::Interface) | ForEach-Object {
        $ManifestPath = $_;
        if($ManifestPath -notlike "*Factory.psd1") {
            Write-Host "Loading (using) - $ManifestPath";
            $scriptBlock += "using Module $ManifestPath;`n";
            
    }
}
# Second iteration will import all Non-Interface Modules
# This cannot be merged with the loop above because all
# Interfaces needs to be loaded first before concrete classes.
GetAllModuleManifestPaths -ManifestType ([ManifestType]::NonInterface) | ForEach-Object {
    $ManifestPath = $_;
    if($ManifestPath -notlike "*Factory.psd1") {
        Write-Host "Loading (using) - $ManifestPath";
        $scriptBlock += "using Module $ManifestPath;`n";
    }
}
$script = [scriptblock]::Create($scriptBlock);
$script;
. $script;

Execute;
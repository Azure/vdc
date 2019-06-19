
Function Get-UniqueString ($value, $length=24)
{   
    $sha512 = [System.Security.Cryptography.SHA512Managed]::new();
    $hash = $sha512.ComputeHash($value.ToCharArray());
    # Ensures that the appended value is within the 26 chars in the alphabet ($_ % 26)
    # and starts from lower 'a' -> [byte][char]'a' returns 97
    -Join @($hash[1..$length] | ForEach-Object { [char]($_ % 26 + [byte][char]'a') })
}

Function Get-PathFromFileFunction() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        $Path
    )

    # regex to match the pattern below:
    # File(/archetype.json)
    $extraStringbetweenQuotesRegex = "File\((.*)\)";

    # check if the path matches the regex pattern specified
    if($Path -match $extraStringbetweenQuotesRegex) {
        # extract and return the path
        $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase;
        $match = [regex]::Match($Path, $extraStringbetweenQuotesRegex, $options);
        return $match.Groups[1].Value;
    }
    else {
        return $Path;
    }
}

Function ConvertTo-AbsolutePath() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        $Path,
        [Parameter(Mandatory=$false)]
        $RootPath
    )

    # This will hold the full path of the file being read.
    # Value to be set later in this method based on absolute 
    # or relative path being passed to this method.
    $fullFilePath = "";

    # checks if the path being passed is absolute or relative path
    # IsPathRooted method returns true if the first character is a 
    # directory separator character such as "\", or if the path starts
    # with a drive letter and colon (:). For example, it returns true 
    # for path strings such as "\\MyDir\\MyFile.json", "C:\\MyDir", or 
    # "C:MyDir". It returns false for path strings such as "MyDir".

    # So, in our file() function, we will have to enter the path in 
    # the following format to be relative paths: “./MyFile.json”, 
    # “MyFile.json”. Format “c:\MyFile.json”, “/MyFile.json” are 
    # considered absolute paths.
    $isAbsolutePath = [System.IO.Path]::IsPathRooted($Path);

    # Branch based on whether the path is absolute or relative path
    if($isAbsolutePath) {
        # Since it is absolute, the filePath is the fullFilePath
        $fullFilePath = $Path;
    }
    else {
        # If the path is relative path, we always assume that the 
        # relative path is in the format below irrespective of the OS
        # "Directory-A/Directory-B/Directory-C/File-A.json"

        # To make it OS specific, we split and then combine using
        # [IO.Path]::Combine() method which returns OS specific file
        # or folder path formats
        $Path = [IO.Path]::Combine($Path.Split('/'));

        # "fullFilePath" is a combination of the archetype definition
        # file's parent folder and current file's relative path
        $fullFilePath = Join-Path $RootPath $Path;
    }

    # Test if the path is valid
    $fileExists = Test-Path -Path $fullFilePath;
    
    # Return path if file exists (truthy)
    if($fileExists -eq $true) {
        return (Get-Item -Path $fullFilePath).FullName;
    }
    else {
        throw "File does not exists, path: $fullFilePath";
    }
}

Function Get-ParentFolder() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        $Path
    )

    # Test if the path is valid
    $fileExists = Test-Path -Path $Path;

    # Check if truthy for file existence before 
    # retrieving the parent folder
    if($fileExists -eq $true) {
        return (Get-Item -Path $Path).DirectoryName;
    }
    else {
        Write-Error "File / Folder does not exists";
        throw $_;
    }
}

Function Get-ContentFromPath() {
    [CmdletBinding()]    
    Param(
        [Parameter(Mandatory=$true)]
        $Path
    )

    # get content from file path without any encoding
    $content = Get-Content $Path -Raw;

    # Remove line breaks
    $content = $content.Replace("`r`n",'')

    # convert from string to object and return the object
    return (ConvertFrom-Json $content -Depth 100);
}

Function ConvertTo-HashTable() {
    [CmdletBinding()] 
    Param(
        [Parameter(Mandatory=$false)]
        $InputObject
    )

    if($InputObject) {
        # Convert to string prior to converting to 
        # hashtable
        $objectString = `
            ConvertTo-Json `
                -InputObject $InputObject `
                -Depth 100;

        # Convert string to hashtable and return it
        return `
            ConvertFrom-Json `
                -InputObject $objectString `
                -AsHashtable;
    }
    else {
        return $null;
    }
}

Function Get-AzureDevOpsAuditEnvironmentVariables {
    try {
        return @{
            BuildId = `
                Get-PowershellEnvironmentVariable `
                    -Key "BUILD_BUILDID"
            BuildName = `
                Get-PowershellEnvironmentVariable `
                    -Key "BUILD_DEFINITIONNAME"
            CommitId = `
                Get-PowershellEnvironmentVariable `
                    -Key "BUILD_SOURCEVERSION"
            CommitMessage = `
                Get-PowershellEnvironmentVariable `
                    -Key "BUILD_SOURCEVERSIONMESSAGE"
            CommitUsername = `
                Get-PowershellEnvironmentVariable `
                    -Key "BUILD_SOURCEVERSIONAUTHOR"
            BuildQueuedBy = `
                Get-PowershellEnvironmentVariable `
                    -Key "BUILD_QUEUEDBY"
            ReleaseId = `
                Get-PowershellEnvironmentVariable `
                    -Key "Release.ReleaseId"
            ReleaseName = `
                Get-PowershellEnvironmentVariable `
                    -Key "Release.ReleaseName"
            ReleaseRequestedFor = `
                Get-PowershellEnvironmentVariable `
                    -Key "Release.Deployment.RequestedFor"
        }
    }
    catch {
        Write-Host "An error ocurred while running Get-AzureDevOpsAuditEnvironmentVariables";
        Write-Host $_;
        throw $_;
    }
}

Function Get-PowershellEnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Key
    )
    try {
        # Environment variables are stored as 
        # Dictionaries, therefore we need to call
        # .Value to get the proper value, otherwise
        # we'll get a Dictionary object.
        return `
            (Get-Item Env:$Key `
                -ErrorAction SilentlyContinue).Value;
    }
    catch {
        Write-Host "An error ocurred while running Get-PowershellEnvironmentVariable";
        Write-Host $_;
        throw $_;
    }
}
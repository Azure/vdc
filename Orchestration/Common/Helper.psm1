
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

Function Test-IsLoggedIn() {
    [CmdletBinding()]

    $context = Get-AzContext
    return ($null -ne $context)
}

Function Test-JsonContent() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        $Content
    )

    try {
        if(![string]::IsNullOrEmpty($Content)) {
            # Test-Json does not correctly check all string for Json conversion. Some strings
            # that are convertible to Json fails Test-Json check. So, we need to rely
            # on ConvertFrom-Json directly. However doing so will result in exception
            # being thrown by ConvertFrom-Json if an invalid / non-json string is passed.
            ConvertFrom-Json `
                -AsHashtable `
                -InputObject $Content `
                -Depth 50 | Out-Null;

            # If the conversion from string to json object is sucessful, then it will
            # not error out. So, we return true.
            return $true;
        }
        else {
            # Empty string values should evaluate to false.
            return $false;
        }

    }
    catch {
        # If we reach this block, then it means the conversion has failed. So, we
        # return false.
        return $false;
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

Function Format-DeploymentOutputs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]
        $DeploymentOutputs
    )

    try {
        $outputs = @{};
        if ($null -ne $DeploymentOutputs) {
            Write-Debug "Deployment outputs type is: $($DeploymentOutputs.GetType())";

            # DeploymentOutputs are exposed as a Dictionary
            if (!$DeploymentOutputs.GetType().`
                ToString().`
                ToLower().`
                Contains("system.collections.generic.dictionary") -and
                !$DeploymentOutputs.GetType().`
                ToString().`
                ToLower().`
                Contains("hashtable"))
            {
                throw "Outputs must be a Hashtable or Dictionary type";
            }

            $DeploymentOutputs.Keys | ForEach-Object {
                $key = $_;

                # We use .Type because a deployment output contains two
                # keys, .Type and .Value.
                if ($DeploymentOutputs.$key.Type.Equals(
                    "Array",
                    [StringComparison]::InvariantCultureIgnoreCase)) {

                    # We are in a case that a deployment output is an array
                    # let's convert the string into a JSON object, let's
                    # loop through it and append the items into a temp array
                    $outputAsArray = @();

                    # Create a new Powershell array only when the type is JArray
                    if ($DeploymentOutputs.$key.Value.GetType().`
                        ToString().`
                        ToLower().`
                        Contains("jarray")){
                        $DeploymentOutputs.$key.Value.ToString() | ConvertFrom-Json `
                        | ForEach-Object {
                            $outputAsArray += $_;
                        }
                    }
                    else {
                        # Otherwise we assume that the Value's type is System.Object[]
                        # This is true when we are getting deployment outputs from
                        # the data store, the data store will read the contents of
                        # a file and will invoke ConvertFrom-Json to create a set of
                        # valid objects
                        $outputAsArray = $DeploymentOutputs.$key.Value;
                    }


                    $outputs += @{
                        $key = @{
                            "Type" = "Array"
                            "Value" = $outputAsArray
                        }
                    };
                }
                else {
                    $outputs += @{
                        $key = @{
                            "Type" = $DeploymentOutputs.$key.Type
                            "Value" = $DeploymentOutputs.$key.Value
                        }
                    }
                }
            }
            return $outputs;
        }
        else {
            Write-Debug "No deployment outputs";
            # No outputs, return null;
            return $null;
        }
    }
    catch {
        Write-Host "An error ocurred while running Format-DeploymentOutputs";
        Write-Host $_;
        throw $_;
    }
}


Function Get-Exception {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [object]
        $ErrorObject
    )

    # Print out stack trace information of the outer error first
    # Example Inheritance chain for TaskCanceledException
    # Object --> Exception --> SystemException --> OperationCanceledException --> TaskCanceledException
    if($errorObject -is [System.Exception]) {
        Write-Debug "Stack Trace - $($errorObject.StackTrace)";
    }
    # Inheritance chain for ErrorRecord
    # Object --> ErrorRecord
    elseif($errorObject -is [System.Management.Automation.ErrorRecord]) {
        Write-Debug "Stack Trace - $($errorObject.ScriptStackTrace)";
    }

    # Get Inner Exception Message from the error object
    if($errorObject -is [System.Management.Automation.ErrorRecord] `
        -and $null -ne $errorObject.details `
        -and $errorObject.details.Count -gt 0) {
            return $($errorObject.details[0]);
    }
    elseif($errorObject -is [System.Management.Automation.ErrorRecord] `
        -and $null -ne $errorObject.Exception) {
            return `
                Get-Exception $errorObject.Exception;
    }
    elseif($errorObject -is [System.Exception] `
        -and $null -ne $errorObject.ErrorRecord) {
            return `
                Get-Exception $errorObject.ErrorRecord;
    }
    else {
        return $errorObject.Message;
    }
}

Function Start-ExponentialBackoff () {
    param (
        [Parameter(Mandatory)]
        #[ValidateScript({ $_.Ast.ParamBlock.Parameters.Count -eq 1 })]
        [Scriptblock] $Expression,
        [Parameter(Mandatory=$false)]
        [Object[]] $Arguments = @(),
        [Parameter(Mandatory=$false)]
        [int] $MaxRetries = 3
    )
    $innerException = "";
    While($MaxRetries -gt 0) {
        try {
            return `
                Invoke-Command `
                    -ScriptBlock $Expression `
                    -ArgumentList $Arguments;
        }
        catch [System.Threading.Tasks.TaskCanceledException] {
            $newWait = ($i * 60);
            Write-Debug "Sleeping for: $newWait seconds";
            Start-Sleep -Seconds ($i * 60);
            $MaxRetries--;
            if($MaxRetries -eq 0) {
                $innerException = Get-Exception -ErrorObject $_;
            }
        }
        catch {
            Throw `
                $(Get-Exception -ErrorObject $_);
        }
    }

    throw "Maximum number of retries reached. Number of retries: $MaxRetries. InnerException: $innerException";
}

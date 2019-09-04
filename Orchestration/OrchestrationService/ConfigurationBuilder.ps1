$rootPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$helperPath = Join-Path $rootPath -ChildPath '..' -AdditionalChildPath @('Common', 'Helper.psm1');
Import-Module $helperPath;

Class ConfigurationBuilder {

    $configurationInstanceAsObject = $null;
    $configurationInstanceName = "";
    $configurationDefinitionParentFolder = "";
    $configurationDefinitionFileName = "";
    $fileFunctionResolutionDepthLimit = 20;

    ConfigurationBuilder([string] $configurationInstanceName, 
                         [string] $configurationDefinitionPath) {
        # setting the configuration name for use with token parser
        $this.configurationInstanceName = $configurationInstanceName;
        
        # check if the path is valid path
        $filePathExists = Test-Path -Path $configurationDefinitionPath;
        if($filePathExists) {
            # configurationDefinitionParentFolder variable will be used to set 
            # the base folder for all relative paths. Relative paths are
            # relative to the configuration definition file's parent folder.
            $this.configurationDefinitionParentFolder = (Get-Item $configurationDefinitionPath).DirectoryName;
            $this.configurationDefinitionFileName = (Get-Item $configurationDefinitionPath).Name;
        }   
        else {
            throw "ConfigurationDefinitionPath - $configurationDefinitionPath is invalid";
        }
    }

    [hashtable] BuildConfigurationInstance($func) {

        # Get the absolute path to the configuration definition file
        $configurationDefinitionPath = `
            Join-Path `
                $this.configurationDefinitionParentFolder `
                $this.configurationDefinitionFileName;
        
        # Process the configuration definition file passing the absolute
        # path.
        $configurationInstanceContent = `
            $this.ProcessFile($configurationDefinitionPath, 0);

        # Convert the resultant string from previous step to an
        # object. We cannot convert this to hashtable here because
        # the ReplaceTokens function expects an object
        $this.configurationInstanceAsObject = `
            ConvertFrom-Json `
                -InputObject $configurationInstanceContent `
                -Depth 100;

        if ($null -ne $func) {
            # Before replacing the tokens, let's run the 
            # callback, the callback has a requirement,
            # which is that it always receives one argument
            # ConfigurationInstance as an object
            Invoke-Command `
                -ScriptBlock $func `
                -ArgumentList $this.configurationInstanceAsObject;
        }

        # Replace Tokens in Configuration Instance
        $this.configurationInstanceAsObject = `
            $this.ReplaceTokens($this.configurationInstanceAsObject);

        # Convert to hashtable and return Configuration Instance
        $configurationInstanceAsHashtable = `
            ConvertTo-HashTable `
                -InputObject $this.configurationInstanceAsObject;
      
        # This condition is required to filter out objects that do not meet the structural requirements.
        # Since BuildConfigurationInstance() method is called for building other objects (like tookit 
        # configuration), we do not want to process all objects through RetainScriptArgumentsOrder() method.
        if( $null -ne $this.configurationInstanceAsObject.Orchestration.ModuleConfigurations -and `
            $this.configurationInstanceAsObject.Orchestration.ModuleConfigurations -is [array] ) {
                return `
                    $this.RetainScriptArgumentsOrder(
                        $this.configurationInstanceAsObject, 
                    $configurationInstanceAsHashtable
                );
        }
        else {
            return $configurationInstanceAsHashtable;
        }
    }

    hidden [hashtable] RetainScriptArgumentsOrder([object] $configurationInstanceAsObject, [hashtable] $configurationInstanceAsHashtable) {

        # ConfigurationInstanceAsObject - is of type PSCustomObject. This will be used as reference
        # object going forward since this object preserves the order of its properties.
        # ConfigurationInstnaceAsHashtable - is of type Hashtable. This will be used as actual object
        # to be returned and will be modified during the course of this function.
        # Get only module configurations that invoke scripts.
        $configurationInstanceAsHashtable.Orchestration.ModuleConfigurations | Where-Object {
            $null -ne $_.Script
        } | ForEach-Object {
            # Assign the current module configuration to the actualModule var. This is object of 
            # type hashtable.
            $actualModule = $_;

            # Retrieve the reference module configuration which will be an object of type PSCustomObject.
            $referenceModule = $configurationInstanceAsObject.Orchestration.ModuleConfigurations | ? { $_.Name -eq $actualModule.Name };
            
            # Override the "arguments" property of actualModule var whose type is hashtable with "arguments"
            # property of referenceModule var whose type is PSCustomObject.
            if($actualModule.Script.Arguments -is [hashtable] -and `
                $actualModule.Script.Arguments.Keys.Count -gt 0 ) {
                $actualModule.Script.Arguments = $referenceModule.Script.Arguments;
            }
        }

        # Return the configurationInstanceAsHashtable object. But this object is not a pure hashtable.
        # That is, one or more child value are PSCustomObject types.
        return $configurationInstanceAsHashtable;
    }
    
    hidden [string] ProcessFile([string] $filePath, [int] $depthLimit) {

        # Increment the depth before each file processing
        $depthLimit++;

        # Get the file Content from absolute filePath
        $fileContentString = `
            Get-Content -Path $filePath -Raw;

        # Get the file's parent path
        $fileParentPath = `
            Get-ParentFolder -Path $filePath;

        # Check if the file has file or env functions
        if($this.IsFileFunctionPresent($fileContentString) -or `
           $this.IsEnvironmentFunctionPresent($fileContentString)) {

            # Hold the file function references in an array
            $fileFunctionExtracts = @();

            # Extract all the file fns and relative paths in the file fns
            $fileFunctionExtracts = `
                $this.ExtractAllFileFunctionsFromFileContent(
                    $fileContentString
                );
            
            # Convert the relative paths to absolute path
            $fileFunctionExtracts | ForEach-Object {

                # This value contains a value something like this (including
                # quotes):
                # "file(../foo.json)"
                $fullFileFunctionReference = $_;

                # Get Path from the full file function string
                $pathFromFullFileFunctionString = `
                    $this.GetPathFromFileFunction($fullFileFunctionReference);

                # Get Absolute Path from Relative Path
                $absolutePathOfPathFromFullFileFunctionString = `
                    ConvertTo-AbsolutePath `
                        -RootPath $fileParentPath `
                        -Path $pathFromFullFileFunctionString;

                if($depthLimit -le $this.fileFunctionResolutionDepthLimit) {
                    
                    # Recursively call this method again for processing nested file
                    # functions
                    $referencedFileContent = `
                        $this.ProcessFile(
                            $absolutePathOfPathFromFullFileFunctionString,
                            $depthLimit
                        );
                }
                else {
                    throw ("File function resolution is limited to {0} level. Your `
                            file contains more than the allowed nested file functions." `
                             -F $this.fileFunctionResolutionDepthLimit);
                }
                
                # Now replace all the relative paths with absolute paths
                $referencedFileContent = `
                    $this.ResolvePathsToAbsolutePathsInFile(
                        $absolutePathOfPathFromFullFileFunctionString, 
                        $referencedFileContent
                    );

                # Replace \ with \\ to create a valid JSON
                # \ only comes after resolving an absolute path
                # in Windows OS.
                $referencedFileContent = `
                    $referencedFileContent.Replace("\", "\\");

                # Check for json objects before replacing it
                $isJson = `
                    Test-Json `
                        -Json $referencedFileContent `
                        -ErrorAction SilentlyContinue;

                if(!$isJson) {
                    # If the file content is not convertible to json, then replace the 
                    # content without replacing the single or double quotes. Since
                    # fullFileFunctionReference contains a value similar to (including
                    # quotes):
                    # "file(../foo.json)"
                    # We remove the quotes from fullFileFunctionReference so we
                    # can replace file(../foo.json) (without quotes)
                    # with whatever string we got by reading the contents of the file
                   
                    $fullFileFunctionReference = `
                        $fullFileFunctionReference.`
                            Replace("`"", "").`
                            Replace("'", "");
                }

                # Replace the file function
                $fileContentString = `
                    $fileContentString.Replace(
                        $fullFileFunctionReference, 
                        $referencedFileContent
                    );
            }

            $environmentKeyExtracts = @();

            # Extract all the file fns and relative paths in the file fns
            $environmentKeyExtracts = `
                $this.ExtractAllEnvironmentFunctionsFromContent(
                    $fileContentString
                );

            # Let's loop through all the Environment keys found
            $environmentKeyExtracts | ForEach-Object {

                # This value contains a value something like this (including
                # quotes):
                # "env(foo)"
                $fullEnvironmentKeyReference = $_;

                $environmentKey = `
                    $this.GetEnvironmentKeyFromEnvironmentFunction(
                        $fullEnvironmentKeyReference);

                # Get environment key by invoking a helper function
                $environmentValue = `
                    Get-PowershellEnvironmentVariable `
                        -Key $environmentKey.ToUpper();

                if ($null -eq $environmentValue) {
                    throw "Environment key not found: $($environmentKey)";
                }

                # Replace \ with \\ to create a valid JSON
                # \ only comes after resolving an absolute path
                # in Windows OS.
                $environmentValue = `
                    $environmentValue.Replace("\", "\\");
                
                # Check for json objects before replacing it
                $isJson = `
                    Test-Json `
                        -Json $environmentValue `
                        -ErrorAction SilentlyContinue;

                if (!$isJson) {
                    # If the file content is not convertible to json, then replace the 
                    # content without replacing the single or double quotes. Since
                    # fullFileFunctionReference contains a value similar to (including
                    # quotes):
                    # "env(foo)"
                    # We remove the quotes from fullFileFunctionReference so we
                    # can replace env(foo) (without quotes)
                    # with whatever string we got by reading the environment variable
                    $fullEnvironmentKeyReference = `
                        $fullEnvironmentKeyReference.`
                            Replace("`"", "").`
                            Replace("'", "");
                }

                # Replace the ENV: key
                $fileContentString = `
                    $fileContentString.Replace(
                        $fullEnvironmentKeyReference, 
                        $environmentValue
                    );
            }
            return $fileContentString;
        }
        else {
            return $fileContentString;
        }
    }

    hidden [array] ExtractAllEnvironmentFunctionsFromContent([string] $environmentContentString) {
        
        # Return will be an array of all environment keys
        $environmentExtracts = @();

        $environmentExtractionRegex = "([`"`"E\''E]+NV\(.*?[`"\'\)]+)";

        # Check if the path matches the regex pattern specified,
        # extract and return match
        $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase;
        $matches = [regex]::Matches($environmentContentString, $environmentExtractionRegex, $options);
        $matches | ForEach-Object { 
            # If there is a match, return the entire match, in this case
            # it will be "env(FOO)" for example (including the quotes, single
            # or double)
            
            # We do .Groups[1] to get the entire match including quotes.
            $match = $_.Groups[1].Value;

            if(-not $environmentExtracts.Contains($match)) {
                $environmentExtracts += $match;
            }
        }

        return $environmentExtracts;
    }

    hidden [bool] IsEnvironmentFunctionPresent([string] $environmentContentString) {
        # Regex to match any env() function in a string
        # Example: env(Foo)
        $environmentRegex = "Env\((.*?)\)";;
        
        # Simple check for regex match being truthy
        if($environmentContentString -match $environmentRegex) {
            return $true;
        }
        else {
            return $false;
        }
    }

    hidden [string] GetEnvironmentKeyFromEnvironmentFunction([string]  $fullEnvironmentFunctionReference) {

        # Regex to match the pattern below:
        # env(foo)
        $environmentFunctionRegex = "Env\((.*?)\)";

        # Check if the path matches the regex pattern specified
        if($fullEnvironmentFunctionReference -match $environmentFunctionRegex) {
            # Extract and return the path
            $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase;
            $match = [regex]::Match($fullEnvironmentFunctionReference, $environmentFunctionRegex, $options);
            return $match.Groups[1].Value;
        }
        else {
            return $fullEnvironmentFunctionReference;
        }
    }

    hidden [array] ExtractAllFileFunctionsFromFileContent([string] $fileContentString) {

        # Return will be an array of all the file functions
        $fileFunctionExtracts = @();

        # Regex to match the pattern below:
        # "File(/configuration.json)"
        $fullFileFunctionReferenceRegex = "([`"`"F\''F]+ile\(.*?[`"\'\)]+)";

        # Check if the path matches the regex pattern specified,
        # extract and return the path (including quotes, single or double)
        $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase;
        $matches = [regex]::Matches($fileContentString, $fullFileFunctionReferenceRegex, $options);
        $matches | ForEach-Object { 
            $match = $_.Groups[1].Value;
            if(-not $fileFunctionExtracts.Contains($match)) {
                $fileFunctionExtracts += $match;
            }
        }

        return $fileFunctionExtracts;
    }

    hidden [bool] IsFileFunctionPresent([string] $fileContentString) {

        # Regex to match any file functions in a string
        # Example: file(/home/user/demo.json)
        $fileFunctionPathOnlyRegex = "File\((.*?)\)";

        # Simple check for regex match being truthy
        if($fileContentString -match $fileFunctionPathOnlyRegex) {
            return $true;
        }
        else {
            return $false;
        }
    }

    hidden [string] ResolvePathsToAbsolutePathsInFile([string] $filePath, [string] $fileContentString) {

        # Get all paths from the file Content
        $pathExtracts = `
            $this.ExtractAllPathFromFileContent($fileContentString);

        # Get the parent folder of the file being processed.
        # This will be the root path to all the relative paths 
        # extracted from the file contents.
        $fileParentFolder = `
            Get-ParentFolder `
                -Path $filePath;

        # Iterate through all paths extracted from the file content
        $pathExtracts | ForEach-Object {

            # Get the paths extract.
            # Assume it is always relative path
            $relativePath = $_;

            try {
                # Resolve relative path to absolute path
                $absolutePath = `
                    ConvertTo-AbsolutePath `
                        -Path $relativePath `
                        -RootPath $fileParentFolder;

                # Before we proceed to replace, make sure the absolute path returned
                # is not the same as relative path. This is the case when the user 
                # has already entered an absolute path that did not require resolving.
                if($absolutePath -ne $relativePath) {
                    # Replace relative path to absolute path
                    $fileContentString = `
                        $fileContentString.Replace($relativePath, $absolutePath);
                }
            }
            Catch {
                # Throw an exception if we're unable to resolve relative path to absolute path
                throw ("Unable to resolve the file path {0} in file located at {1}" -F $relativePath, $filePath);
            }
        }

        return $fileContentString;
    }

    hidden [array] ExtractAllPathFromFileContent([string] $fileContentString) {
        
        # Return will be an array of all the paths
        # (relative paths and absolute paths)
        $pathExtracts = @();

        # Regex to capture all the patterns below:
        # "TemplatePath": "../../modules/2.0/deploy.json",
        # "TemplatePath": "../../../modules.json",
        # "TemplatePath": "/modules/2.0/deploy.json",
        # "TemplatePath": "/modules.json",
        # "TemplatePath": "./modules/StorageAccounts/2.0/deploy.json",
        # Note: Regex does not capture the below cases:
        # "TemplatePath": "modules/2.0/deploy.json",
        # "TemplatePath": "modules.json",
        # TODO: Include the above two cases
        $pathExtractionRegex = "[`"\']([\.\/]+.*?[.]?)[`"\']";

        # Check if the path matches the regex pattern specified,
        # extract and return the path
        $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase;
        $matches = [regex]::Matches($fileContentString, $pathExtractionRegex, $options);
        $matches | ForEach-Object { 
            $match = $_.Groups[1].Value;
            if(-not $pathExtracts.Contains($match) `
                -and $match -notlike '/subscription*') {
                $pathExtracts += $match;
            }
        }

        return $pathExtracts;
    }

    hidden [string] GetPathFromFileFunction([string]  $fullFileFunctionReference) {

        # Regex to match the pattern below:
        # File(/configuration.json)
        $fileFunctionPathOnlyRegex = "File\((.*?)\)";

        # Check if the path matches the regex pattern specified
        if($fullFileFunctionReference -match $fileFunctionPathOnlyRegex) {
            # Extract and return the path
            $options = [Text.RegularExpressions.RegexOptions]::IgnoreCase;
            $match = [regex]::Match($fullFileFunctionReference, $fileFunctionPathOnlyRegex, $options);
            return $match.Groups[1].Value;
        }
        else {
            return $fullFileFunctionReference;
        }
    }

    hidden [object] ReplaceTokens([object] $configurationInstance) {

        # this variable will hold the processed configuration instance
        # that will have all the tokens replaced with values
        $configurationInstanceWithoutTokens = $null;

        # create an instance of TokenReplacementService
        $tokenReplacement = [TokenReplacementService]::new();

        # call ReplaceAllTokens method to replace the tokens
        # Reference values and token
        $configurationInstanceWithoutTokens = $tokenReplacement.ReplaceAllTokens(
            $this.configurationInstanceName, 
            $configurationInstance,
            $configurationInstance
        );

        # return the token replaced configuration instance
        return $configurationInstanceWithoutTokens;
    }
}
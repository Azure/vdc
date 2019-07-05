Class TokenReplacementService: ITokenReplacementService {

    $dependencyPropertyPath = "orchestration.module-configuration.modules";
    $resourceGroupNamePattern = '${general.organization-name}-${general.{archetype}.deployment-name}-{module}-rg';
    $tokenRegex = "\$\{(.*?)\}";
    $defaultParameterPrefix = 'vdc_defaultparameters_';


    [System.Object] ReplaceAllTokens(   [string] $archetype, `
                                        [System.Object] $tokenizedObject, `
                                        [System.Object] $tokenValue) {

        Try{
            $tokenizedObject = $this.ProcessTokens($archetype, $tokenValue, $tokenizedObject);
        }
        Catch{
            Write-Host "An exception was encountered when trying to replace tokens";
            Write-Host $_;
            Throw $_;
        }
        return $tokenizedObject;
    }

    hidden [System.Object] ProcessTokens(   [string] $archetype, `
                                            [System.Object] $referenceValues, `
                                            [System.Object] $objectToAnalyze ) {
        # Pseudocode
        # We will analyse the $objectToAnalyze object recursively and replace its value along the way
        # To start, check the type of the $objectToAnalyze.
        #   - Type is String - Call replaceTokens, retrieve the value and assign the value to the object
        #   - Type is PSCustomObject - Iterate all properties in the object, call processTokens passing the object's property
        #   - Type is Array - Iterate all objects in the array and recursively call processTokens passing the array item
        
        if($objectToAnalyze.PSObject.TypeNames[0].ToString() -eq "System.Management.Automation.PSCustomObject" `
                -and $objectToAnalyze.PSObject.Properties.Length -gt 0)
        {
            # If the object being processed is a PSCustomObject, then iterate through the objects and continue to evaluate recursively
            $objectToAnalyze.PSObject.Properties | ForEach-Object {
                $propName = $_.Name;
                if($null -ne $objectToAnalyze.$propName `
                        -and [bool]($this.HasTokens($objectToAnalyze.$propName))) {
                    $result = $this.ProcessTokens($archetype, $referenceValues, $objectToAnalyze.$propName);
                    $objectToAnalyze.$propName = $result;
                }
            }
            # This is the reference of property within an object
            return $objectToAnalyze;
        }
        elseif ($objectToAnalyze.PSObject.TypeNames[0].ToString() -eq "System.Object[]")
        {
            # If the object that is being traversed is an array, then iterate through the arrays and continue to evaluate recursively
            for($index=0; $index -lt $objectToAnalyze.Length; $index++) {
                if($null -ne $objectToAnalyze[$index] `
                    -and [bool]($this.HasTokens($objectToAnalyze[$index]))) {
                    $result = $this.ProcessTokens($archetype, $referenceValues, $objectToAnalyze[$index]);
                    $objectToAnalyze[$index] = $result;
                }
            }
            # This is the reference of an item within an array
            return $objectToAnalyze;
        }
        elseif($null -ne $objectToAnalyze`
                -and $objectToAnalyze.PSObject.TypeNames[0].ToString() -eq "System.String" `
                -and $objectToAnalyze -match $this.tokenRegex) {

            $result = $this.ReplaceTokens($archetype, $referenceValues, $objectToAnalyze);  

            # At this point, the object returned by the replaceTokens function call may be an object or array with tokens.
            # We determine if it contains tokens by converting the returned object to string and performing a regex match
            # If tokens are found, we call processTokens to process the tokens found in any of the properties of the object
            if($null -ne $result `
                -and $result.PSObject.TypeNames[0].ToString() -ne "System.String" `
                -and [bool]($this.HasTokens($result))) {
                $result = $this.ProcessTokens($archetype, $referenceValues, $result);
            }
            # This is returning the processed token that is a result of processing a property or item in an array
            # This result can be of any object type
            return $result;
        }
        else {
            throw "Unhandled ObjectToAnalyze Type in processTokens. Excepted Types `
                    System.Object[], System.Management.Automation.PSCustomObject or System.String"
        }
    }

    hidden [bool] HasTokens([System.Object] $objectToAnalyze) {

        $objectString = ConvertTo-Json $ObjectToAnalyze -Depth 50 -Compress;
        if($objectString -match $this.tokenRegex) { 
            return $true
        }
        else {
            return $false;
        }
    }

    hidden [System.Object] GetTokenValue([System.Object] $referenceValues, `
                                                [string] $property,
                                                [string] $archetype) {
        
        # Logic to parse the token without the ${} prefix and suffix
        # Then breakdown into individual property names
        $indexOfProp = 0;
        $regexForIndex = "\[[0-9]+\]"
        $parentObject = $ReferenceValues;
        $Property = $Property -replace "\$\{", ""
        $Property = $Property -replace "\}",""
        $propertyPath = $Property -split "\.";
        foreach($token in $propertyPath) {
            $hasIndexerProperty = $false;
            # Logic to handle indexers in tokens
            # Executed for all the token to analyse if they need indexing or not.
            if($token -match $regexForIndex) {
                # This section deals with tokens with indexers
                # Following code deals with parsing indexer value (i.e, index)
                [regex]$regex = $regexForIndex;
                $indexOfProp = $regex.Matches($token)[0];
                $indexOfProp = $indexOfProp -replace "\[","";
                $indexOfProp = $indexOfProp -replace "\]","";
                # Following code deals with replacing the property with just the property name without the index
                # Example: subNets[0] is replaced with subNets
                $positionOfIndexer = $token.IndexOf("[")
                $token = $token.Substring(0, $positionOfIndexer);
                $hasIndexerProperty = $true;
            }
            
            # There are three cases handled here:
            # Case 1: Environment-Type is replaced with the Archetype passed
            # Case 2: If the segment of the token has indexer, then use indexer
            # Case 3: If the segment of the token does not have indexer, then process as normal
            if($token -eq "ENV:ENVIRONMENT-TYPE") {
                $parentObject = $parentObject.$Archetype;
            }
            # Set Value if the property is index based
            elseif($parentObject.PSObject.Properties.name -match $token -and $hasIndexerProperty) {
                $parentObject = $parentObject.$token[[int]$indexOfProp];
            }
            # Set Value if the property is not index based
            elseif($parentObject.PSObject.Properties.name -match $token) {
                $parentObject = $parentObject.$token;
            }
            else {
                # If we any part of the token is not found, throw error
                $propertyNotFound = $propertyPath -join "."
                throw "Token $propertyNotFound cannot be resolved using ReferenceValues Object passed to getTokenValue function"
            }
        }
        # Calling replaceTokens again because the processed token might have token again
        # Example token = "${workload.deployment-name}-${workload.organization}-la-rg" might be processed to "${general.workload.deployment-alias}-ssvcs-la-rg"
        # So we need to process the token again to get the value for "${general.workload.deployment-alias}-ssvcs-la-rg" until we get a object that does not contain tokens
        if($null -ne $parentObject -and $parentObject.GetType().ToString() -eq "System.String" -and $parentObject -match $this.tokenRegex) {
            # We cannot call getTokenValue because getTokenValue only processes tokens but not a combination of token and string
            # Example: If ${token1} get resolved to ${token2}-ssvcs-rg, this cannot be handled by getTokenValue.
            # We need to go a level higher and call replaceTokens
            return $this.ReplaceTokens($Archetype, $ReferenceValues, $parentObject);
        }
        
        return $parentObject;
        
    }

    hidden [System.Object] ReplaceTokensAndPlaceHolders([System.Object] $referenceValues, `
                                                        [string] $module, `
                                                        [string] $archetype, `
                                                        [System.Object] $objectToAnalyze) {
        # Logic to process placeholders 
        $objectToAnalyze = $objectToAnalyze.replace("{module}", $module.module);
        $objectToAnalyze = $objectToAnalyze.replace("{archetype}", $archetype);
        $objectToAnalyze = $objectToAnalyze.replace("{ENV:ENVIRONMENT-TYPE}", $archetype);

        $tokenValue = $this.ReplaceTokens($archetype, $referenceValues, $objectToAnalyze);
        return $tokenValue;
    }

    hidden [System.Object] ReplaceTokens([string] $archetype, `
                                            [System.Object] $referenceValues, `
                                            [System.Object] $objectToAnalyze) {
        $result = $objectToAnalyze;
        # Check if the value Object passed for analyzing has one or more tokens.
        # If Object has more than one token, process each token in a foreach loop, call getTokenValue to retrieve the value and return the result
        # Example token = "${token1}-${token2}-la-rg" needs to be evaluated separate in a foreach loop - once for token1 and once for token2
        # Limitation: Only tokens that resolve to string value can have mulitple tokens making up a composite token. If they return a object, the
        # object will be processed as string by converting object to strings.
        [regex]$regex = $this.tokenRegex;
        if($objectToAnalyze -match $this.tokenRegex `
            -and $regex.Matches($objectToAnalyze).Count -gt 1) {
            $result = $objectToAnalyze;
            # If it is tokenized, then retrieve the value based on the token path
            # This might need multiple / recursive iterations if the token path contains another token to lookup and so on
            $regex.Matches($objectToAnalyze) | ForEach-Object {
                $tokenName = $_.Value;
                $tokenValue = $this.GetTokenValue($referenceValues, $tokenName, $archetype);
                if($null -ne $tokenValue) {
                    # Replace function is instead of assignment (seem in the else condition) because
                    # token can contains multiple references / sub-tokens inside them
                    # Example: Token: "${general.organization-name}-${general.shared-services.deployment-name}-la-rg"
                    # Replace functions replaces individual token in them in the foreach loop
                    if($tokenValue.GetType().ToString() -ne "System.String") {
                        # ConvertTo-Json is required only for non-string object types
                        # .ToString() function does not convert an object contents to string
                        $tokenValue = ConvertTo-Json $tokenValue -Depth 50 -Compress;
                    }
                    $result = $result.replace("$tokenName","$tokenValue");
                }
            }
        }
        # If Object has only one token, process the token by calling getTokenValue to retrieve the value and return the result.
        # Single tokens can have any object return type - say string, object, array.
        # Example token = "${token1}-la-rg" will be evaluated to retrieve the value of token1
        elseif ($objectToAnalyze -match $this.tokenRegex `
            -and $regex.Matches($objectToAnalyze).Count -eq 1) {
            
            $tokenName = $regex.Matches($objectToAnalyze)[0].Value;
            $result = $this.GetTokenValue($referenceValues, $tokenName, $archetype);
            if($null -ne $result -and $result.GetType().ToString() -eq "System.String") {
                $result = $objectToAnalyze.replace("$tokenName", "$result")
            }
        }
        return $result;
    }

    hidden [System.Object] FindModule([System.Object] $archetypeJson, `
                                        [string] $moduleToFind) {
        $allModules = $this.GetAllModules($archetypeJson);
        $moduleFound = $null;
        forEach($module in $allModules) {
            if($module.module -eq $moduleToFind) {
                $moduleFound = $module;
                break;
            }
        }
        return $moduleFound
    }

    hidden [array] GetModuleDependencies([array] $allModules, `
                                            [string] $moduleToFetchDependency) {
        forEach($module in $AllModules) {
            if($module.module -eq $ModuleToFetchDependency `
                -and $module.PSObject.Properties.Name -match "dependencies") {
                return $module.dependencies;
            }
        }
        return @();
    }

    hidden [array] GetAllModules([System.Object] $archetypeJson) {
        $dependencyProperties = $this.dependencyPropertyPath -split "\.";
        $allModules = @{}

        # Let's set allModules equal to ArchetypeJson
        # this allows us to traverse through the properties:
        # i.e.
        # Let's say that $ArchetypeJson is
        # "orchestration": {
        #   "module-configuration": {
        #       "modules" : [
        #           
        #       ]
        #   } 
        # }
        # $allModules = $ArchetypeJson
        # And loop through all the properties:
        # $allModules getAllModules.orchestration
        # Then $allModules will set its "cursor" in 
        # orchestration property, the next loop will set 
        # $allModules in "module-configuration" and so on
        $allModules = $ArchetypeJson;
        forEach($property in $dependencyProperties) {
            $allModules = $allModules.$property;
        }
        return $allModules;
    }

    hidden [System.Object] IsPartOfDifferentRG([System.Object] $archetypeJson, `
                                                [string] $moduleName) {
        $allModules = $this.GetAllModules($archetypeJson);
        forEach($module in $allModules) {
            # same-resource-group - If set to true, this setting forces dependent resources to deploy in the same resource group as the resource 
            if([bool]($module.PSObject.Properties.name -match "same-resource-group") `
                        -and $module.'same-resource-group' -eq $true `
                        -and [bool]($module.PSObject.Properties.name -match "dependencies") `
                        -and [bool]($module.dependencies -match $moduleName)) {
                return $module.module;
            }
        }
        return $null
    }

    hidden [System.Collections.ArrayList] FetchResourceGroupsForModule([System.Object] $referenceValues, `
                                                                        [string] $moduleName, `
                                                                        [string] $archetype) {
        $resourceGroups = New-Object System.Collections.ArrayList;
        $json = $referenceValues.PSObject.Copy();
        $pathArrayToModule = $this.dependencyPropertyPath -split "\.";
    
        forEach($pathSegment in $pathArrayToModule) {
            $json = $json.$pathSegment;
        }
    
        forEach($module in $json) {
            if($module.module -eq $moduleName) {
                $moduleOfInterest = $module;
                # Gets Resource Group Name of the Module Name passed
                $rgName = $this.GetResourceGroupName($referenceValues.PSObject.Copy(), $archetype, $module.module);
                $resourceGroups.Add($rgName) | Out-Null;
                forEach($dependency in $moduleOfInterest.dependencies) {
                    # Gets Resource Group Name of the Module's dependency
                    $rgName = $this.GetResourceGroupName($referenceValues.PSObject.Copy(), $archetype, $dependency);
                    $resourceGroups.Add($rgName) | Out-Null;
                }
            }
        }
        return $resourceGroups;                                                                 
    }

    hidden [string] GetResourceGroupName([System.Object] $archetypeJson, `
                                            [string] $archetype, `
                                            [string] $moduleName) {
        $resourceGroup = "";
        # checks if the module has a source property with same-resource-group specified, then retrieve the resource group accordingly
        # same-resource-group - If set to true, this setting forces dependent resources to deploy in the same resource group as the resource
        $dependeeModule = isPartOfDifferentRG -ArchetypeJson $ArchetypeJson -ModuleName $ModuleName;
        if($dependeeModule -ne $null) {
            $ModuleName = $dependeeModule;
        }

        $moduleFound = findModule -ArchetypeJson $ArchetypeJson -ModuleToFind $ModuleName
        
        # if the module has a source property with create-resource-group specified, then retrieve the resource group accordingly
        # create-resource-group - If set to false, this setting deploys the resource in the same resource group as its dependency
        if([bool]($moduleFound.PSObject.Properties.name -match "create-resource-group") `
            -and $moduleFound.'create-resource-group' -eq $false `
            -and $moduleFound.dependencies.Count -gt 0) {
                $moduleFound = findModule -ArchetypeJson $ArchetypeJson -ModuleToFind $moduleFound.dependencies[0];
        }
        # After retrieving the dependency module, continue with the normal logic of find the resource group name
        # for the dependency module, which will be the resource group where the module passed to this function
        # will be deployed. So, the if condition above and if else condition below are not mutually exclusive.

        # Once we have the module, then process the module object to retrieve / contruct the resource group name
        # Branch 1: module found and resource-group-name property is present
        # Branch 2: module found and resource-group-name property is absent. Use a default naming convention of resource group name
        # Branch 3: module not found. Use a default naming convention of resource group name
        if($moduleFound -and [bool]($moduleFound.PSObject.Properties.name -match "resource-group-name")) {
            $resourceGroup = $this.ReplaceTokens($Archetype, $ArchetypeJson, $moduleFound.'resource-group-name');
        } elseif ($moduleFound -and $moduleFound.module -ne $null) {
            $resourceGroup = $this.ReplaceTokensAndPlaceHolders($ArchetypeJson, $moduleFound, $Archetype, $this.resourceGroupNamePattern);
        } elseif ($moduleFound.module -eq $null) {
            Write-Warning 'No module found'
            $module = @{ 
                "module"= $ModuleName
            }
            $resourceGroup = $this.ReplaceTokensAndPlaceHolders($ArchetypeJson, $module, $Archetype, $this.resourceGroupNamePattern);
        }

        return $resourceGroup;
    }

    hidden [System.Object] OutputParamsStorageKey([System.Object] $config) {
        $resourceGroupName = $config.'general'.'vdc-storage-account-rg';
        $storageAccountName = $config.'general'.'vdc-storage-account-name';
        $keys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction SilentlyContinue;
        if($keys.Count -gt 0) {
            return $keys[0].Value;
        }
        return $null;
    }

    hidden [string] OutputParamsStorageAccountName([System.Object] $config) {
        $storageAccountName = $config.'general'.'vdc-storage-account-name';
        return $storageAccountName;
    }

    hidden [string] GenerateSASToken([System.Object] $config) {
        $startTime = Get-Date;
        $endTime = $startTime.AddHours(5);
        $resourceGroupName = $config.'general'.'vdc-storage-account-rg';
        $storageAccountName = $config.'general'.'vdc-storage-account-name';

        $accountKeys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName
        $storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $accountKeys[0].Value 

        $sasKey = New-AzureStorageAccountSASToken  -Service "Blob" -ResourceType Service -Context $storageContext -Permission r -StartTime $startTime -ExpiryTime $endTime;

        if ($sasKey.StartsWith("?") -eq $true) {
            $sasKey = $sasKey.substring(1,$sasKey.Length-1);
        }

        return $sasKey;
    }

    hidden [bool] GetStorageAccounts([string] $resourceGroupName, `
                                        [string] $storageAccountName) {
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName -ErrorAction SilentlyContinue;
        if($storageAccount) {
            return $true;
        }
        else {
            return $false;
        }
    }

    hidden [void] CreateStorageAccount([string] $resourceGroupName, `
                                        [string] $storageAccountName, `
                                        [string] $location, `
                                        [string] $storageType) {
        New-AzStorageAccount    -ResourceGroupName $ResourceGroupName 
                                -AccountName $StorageAccountName 
                                -Location $Location 
                                -SkuName Standard_GRS 
                                -Kind $StorageType 
                                -ErrorAction SilentlyContinue;
    }
}
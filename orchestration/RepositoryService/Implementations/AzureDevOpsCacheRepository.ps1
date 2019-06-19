Class AzureDevOpsCacheRepository: ICacheRepository {

    $cacheNamePrefix = "vdc_cache";
    $cacheNameFormat = "{0}_{1}"

    AzureDevOpsCacheRepository() {
        # Constructor overloaded to allow cache name prefix
        # default value usage in case no prefix is to be passed
    }

    AzureDevOpsCacheRepository([string] $cacheNamePrefix) {
        $this.cacheNamePrefix = $cacheNamePrefix;
    }

    [string] GetByKey([string] $key) {

        # key is empty string
        if([string]::IsNullOrEmpty($key)) {
            return $null;
        }

        # let's replace any dots with underscore
        $key = $key.Replace('.', '_');

        # now, let's replace any special character
        # with an empty string, underscores are 
        # excluded from the replace.
        $key = $key -replace '[\W]', '';

        # Add prefix to the key before attempting retrieval.
        # Also, convert "." to underscore and convert the key
        # to uppercase before retriveing the value since the 
        # keys are internally transformed into uppercase and 
        # "." replaced with "_" when performing the set operation.
        $key = ($this.cacheNameFormat -F `
                    $this.cacheNamePrefix, `
                    $key).ToUpper();

        # Check the environemnt variable for the key
        # An invalid key throws an exception, so we 
        # set ErrorAction to SilentlyContinue
        $environmentValue = `
            (Get-Item Env:$key `
                -ErrorAction SilentlyContinue);

        # return type from Get-Item is name-value pair, if present
        # return its Value
        if($null -ne $environmentValue) {
            return $environmentValue.Value;
        }
        else {
            return $null;
        }
    }

    [void] Set([string] $key, `
               [string] $value) {
        
        # perform a set operation only when a key 
        # exists.
        if(![string]::IsNullOrEmpty($key)) {
            # let's replace any dots with underscore
            $key = $key.Replace('.', '_');

            # now, let's replace any special character
            # with an empty string, underscores are 
            # excluded from the replace.
            $key = $key -replace '[\W]', '';

            # add prefix to the key before attempting save
            $key = ($this.cacheNameFormat -F `
                        $this.cacheNamePrefix, `
                        $key);

            # Get the cache value if it already exists
            $environmentValue = $this.GetByKey($key);

            # check before proceeding to update / set the value:
            # 1. non-existence of environment variable
            #  -- or --
            # 2. existence of environment variable and current value is 
            # not same as the new value passed 
            
            if([string]::IsNullOrEmpty($environmentValue) `
                -or `
               (![string]::IsNullOrEmpty($environmentValue) `
                -and $environmentValue -ne $value
               )) {
                Write-Host "##vso[task.setvariable variable=$key;]$value";
            }
        }
    }

    [void] RemoveByKey([string] $key) {
        
        # there is no delete operation for Azure DevOps Pipeline 
        # variable. So, this method will set the value to empty
        # string
        $this.Set($key, "");
    }

    [void] Flush([string] $prefix) {
        Throw "Method Not Implemented";
    }

    [array] GetAll() {
        
        # Get the all environment variables 
        # Get-Item does not support -Filter
        $environmentVariables = Get-Item Env:;

        # Filter the returned variables using the prefix
        $allRelevantVariables = $environmentVariables | Where-Object { $_.Name -like "$($this.cacheNamePrefix)*" };

        # return the filtered variables
        return $allRelevantVariables;
    }
}
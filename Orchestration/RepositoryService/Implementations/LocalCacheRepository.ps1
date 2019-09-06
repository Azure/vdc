Class LocalCacheRepository: ICacheRepository {

    $cacheNamePrefix = "vdc_cache";
    $cacheNameFormat = "{0}_{1}";
    static $memoryCache = $null;

    LocalCacheRepository() {
        [LocalCacheRepository]::memoryCache = `
                New-Object System.Runtime.Caching.MemoryCache('Main');
    }

    [object] GetByKey([string] $key) {

        # key is empty string
        if([string]::IsNullOrEmpty($key)) {
            return $null;
        }

        # Add prefix to the key before attempting retrieval.
        # Also, convert "." to underscore and convert the key
        # to uppercase before retriveing the value since the 
        # keys are internally transformed into uppercase and 
        # "." replaced with "_" when performing the set operation.
        $key = ($this.cacheNameFormat -F `
                    $this.cacheNamePrefix, `
                    $key -replace '[\W]', ''
                ).ToUpper();

        # Check for truthy
        # Return type from Get-Item is name-value pair. If present,
        # return its Value
        if([LocalCacheRepository]::memoryCache.Contains($key)) {
            $cachedValue = [LocalCacheRepository]::memoryCache.Get($key);
            Write-Debug "Key: $key found in cache, with value: $cachedValue"
            return $cachedValue;
        }
        else {
            Write-Debug "Key: $key not found in cache, returning null"
            return $null;
        }
    }

    [void] Set([string] $key, `
               [string] $value) {
        
        $policy = New-Object System.Runtime.Caching.CacheItemPolicy;
        $policy.AbsoluteExpiration = (Get-Date).AddHours(3);
        
        if(![string]::IsNullOrEmpty($key)) {
            # Add prefix to the key before attempting save
            $key = ($this.cacheNameFormat -F `
                        $this.cacheNamePrefix, `
                        $key -replace '[\W]', '').ToUpper();
        }
        else {
            return;
        }
        
        # Truthy - check before proceeding to update / set the value:
        # 1. existence of environment variable and current value is 
        # not same as the new value passed 
        #  -- or --
        # 2. non-existence of environment variable
        if(([LocalCacheRepository]::memoryCache.Contains($key) `
            -and [LocalCacheRepository]::memoryCache.Get($key) -ne $value
           ) `
            -or ![LocalCacheRepository]::memoryCache.Contains($key)) {
            Write-Debug "Caching key: $key with value: $value"
            [void][LocalCacheRepository]::memoryCache.Set($key, $value, $policy);
        }
    }

    [void] RemoveByKey([string] $key) {
        
        if(![string]::IsNullOrEmpty($key)) {
            # Add prefix to the key before attempting save
            $key = ($this.cacheNameFormat -F `
                        $this.cacheNamePrefix, `
                        $key -replace '[\W]', '').ToUpper();
        }
        else {
            return;
        }
        
        [LocalCacheRepository]::memoryCache.Remove($key);
    }

    [void] Flush() {
        
        # Get all key names of the cached items
        $cachedItems = $this.GetAll();

        # Iterate through all the keys and remove them
        # one by one.
        $cachedItems.Keys | ForEach-Object {
            [LocalCacheRepository]::memoryCache.Remove($_);
        }
    }

    [array] GetAll() {
        
        $cachedItems = @();

        # Get all key names of the cached items
        [array]$cacheItems = `
            [LocalCacheRepository]::memoryCache;

        # Convert Array of DictionaryEntries to Array of Hashtables
        $cacheItems | ForEach-Object {
            $cachedItems += @{ $_.Key = $_.Value };
        }

        # return the array
        return $cachedItems;
    }
}
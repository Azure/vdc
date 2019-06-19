Class LocalStorageAuditRepository: IAuditRepository {

    $storageAccountContext = $null;
    $auditContainerName = "audit";
    $mappingContainerName = "mappings";
    $rootPath = "";

    # auditDirectory has the following format
    # auditContainerName/archetypeInstanceName
    $auditDirectory = "{0}/{1}";
    
    $auditFileName = "{0}.json";
    
    # mappingsDirectory has the following format
    # mappingContainerName/archetypeInstanceName
    $mappingsDirectory = "{0}/{1}";

    # mappingsDirectory has the following format
    # mappingContainerName/auditMappings.json
    $mappingsFileName = "auditMappings.json"

    LocalStorageAuditRepository() {
        # TODO: Get value from cache
        $this.rootPath = `
            $ENV:vdc_localAuditPath;
    }

    # entity is a wrapper around the collection of data
    # that is being stored in the repository
    [void] SaveAuditTrail([object] $entity) {

        # Getting defaults
        $archetypeInstanceName = `
            $entity.ArchetypeInstanceName; 
        $auditId = `
            $entity.AuditId;

        try {
            # Let's create a directory string based on the 
            # formatted string from above ($this.auditDirectory)
            # Formatted string ($this.auditDirectory) contains slashes as 
            # delimiter
            $newAuditDirectory = $this.auditDirectory -F `
                $this.auditContainerName, `
                $archetypeInstanceName;
            
            # Let's normalize the directory by passing a string
            # array, the result will be an OS specific directory
            # path
            $newAuditDirectory = `
                $this.NormalizeFilePath(
                    $newAuditDirectory.Split('/'));
            
            # Let's add the root path
            $newAuditDirectory = `
                $this.NormalizeFilePath(
                        @($this.rootPath) + $newAuditDirectory);
            
            # Let's create the directory
            $this.CreateDirectory($newAuditDirectory);
            
            # Let's generate a file name
            $newAuditFileName = $this.auditFileName -F `
                $auditId;

            # Let's add the file name and generate
            # an absolute path
            # In this case, both are single strings, so is ok to 
            # create a single array @()
            $auditAbsolutePath = `
                $this.NormalizeFilePath(
                    @($newAuditDirectory, $newAuditFileName));
            
            # Let's save the file contents
            ConvertTo-Json $entity `
                -Depth 100 `
                -Compress > $auditAbsolutePath;
        }
        catch {
            Write-Host "An error ocurred while running LocalStorageAuditRepository.SaveAuditTrail";
            Write-Host $_;
            throw $_;
        }
    }

    [void] SaveAuditTrailAndDeploymentIdMapping([object] $entity) {
        # Getting defaults
        $archetypeInstanceName = `
            $entity.ArchetypeInstanceName;
        $auditId = `
            $entity.AuditId;
        
        # Let's create mapping contents object
        # this object contains a module instance
        # name and deployment id mapping
        $mappingsContent = @{
            $archetypeInstanceName = @{
                AuditId = $auditId
            }
        }
        
        try {
            # Let's create a directory string based on the 
            # formatted string from above ($this.mappingsDirectory)
            # Formatted string ($this.mappingsDirectory) contains slashes as 
            # delimiter
            $newMappingsDirectory = $this.mappingsDirectory -F `
                $this.mappingContainerName, `
                $archetypeInstanceName;

            # Let's generate a path that is OS agnostic
            $newMappingsDirectory = `
                $this.NormalizeFilePath(
                    @($this.rootPath) + $newMappingsDirectory.Split('/'));

            # Let's create the directory
            $this.CreateDirectory($newMappingsDirectory);

            # Let's the file name and generate an absolute path
            # In this case, both are single strings, so is ok to 
            # create a single array @()
            $mappingsAbsolutePath = `
                $this.NormalizeFilePath( 
                    @($newMappingsDirectory, $this.mappingsFileName));
            
            # Let's check if the file exists
            $fileExists = Test-Path $mappingsAbsolutePath;

            # If file exists, open it and read its contents
            if ($fileExists) {
                # Convert the contents into a hashtable 
                $mappingsJson = `
                    Get-Content $mappingsAbsolutePath -Raw | `
                    ConvertFrom-Json `
                        -Depth 100 `
                        -AsHashTable;
                
                # If a value does not exists,
                # append $mappingsContent to the existing
                # file contents ($mappingsJson)

                # Checking for truthy
                if ($mappingsJson.$archetypeInstanceName) {
                    # Let's update the previous auditId value
                    $mappingsJson.$archetypeInstanceName.AuditId = `
                        $auditId;
                } 
                else {
                    # Mapping does not exist, proceed to
                    # append a new mapping
                    $mappingsJson += $mappingsContent;
                }

                # Let's update $mappingsContent
                # with the updated set of mappings
                # this allows us to use one single
                # variable when saving the new contents
                $mappingsContent = $mappingsJson
            }

            # Let's save the mapping
            ConvertTo-Json $mappingsContent `
                -Depth 100 `
                -Compress > $mappingsAbsolutePath;
        }
        catch {
            Write-Host "An error ocurred while running LocalStorageAuditRepository.SaveAuditTrailAndDeploymentMapping";
            Write-Host $_;
            throw $_;
        }
    }

    [void] GetAuditTrailByCommitId ([object] $commitId) {
        Throw "Method Not Implemented";
    }

    [hashtable] GetAuditTrailByFilters([string] $filters) {

        try {
            if($filters.Count -ge 2) {
                # File name is derived from the filters array
                # $filters parameter assumes to contain the 
                # following information:
                # Index 0 - Archetype Instance Name
                # Index 1 - Audit Id

                # Getting defaults
                $archetypeInstanceName = `
                    $filters[0];
                $auditId = `
                    $filters[1];
                
                # Let's create a directory string based on the 
                # formatted string from above ($this.auditDirectory)
                # Formatted string ($this.auditDirectory) contains slashes as 
                # delimiter
                $newAuditDirectory = $this.auditDirectory -F `
                    $this.auditContainerName, `
                    $archetypeInstanceName;
                
                # Let's generate a path that is OS agnostic
                $newAuditDirectory = `
                    $this.NormalizeFilePath($newAuditDirectory.Split('/'));
            
                # Let's generate a file name
                $newAuditFileName = $this.auditFileName -F `
                    $auditId;

                # Let's add the file name and generate
                # an absolute path (single strings should
                # be converted into arrays)
                $auditAbsolutePath = `
                    $this.NormalizeFilePath(
                        @($this.rootPath) + $newAuditDirectory + @($newAuditFileName));
                
                # Let's check if the file exists
                $fileExists = Test-Path $auditAbsolutePath;
                
                # If file exists, retrieve data
                if($fileExists) {
                    # Read the contents of the file, convert to JSON object
                    # and return the object
                    $contentJson = `
                        Get-Content $auditAbsolutePath `
                            -Raw `
                        | ConvertFrom-Json `
                            -AsHashtable `
                            -Depth 100;
                    return $contentJson;
                }
                else {
                    # file was not found
                    return $null;
                }
            }
            else {
                throw "Filters Argument must be of length 2";
            }
        }
        catch {
            Write-Host "An error ocurred while running LocalStorageAuditRepository.GetAuditTrailById";
            Write-Host $_;
            throw $_;
        }
    }

    [object] GetAuditTrailByUserId([object] $userId) {
        Throw "Method Not Implemented";
    }

    [object] GetAuditTrailByBuildId([object] $buildId) {
        Throw "Method Not Implemented";
    }

    [hashtable] GetLatestAuditMapping([object[]] $filters) {
        
        try {
            if($filters.Count -ge 2) {
                # File name is derived from the filters array
                # $filters parameter assumes to contain the 
                # following information:
                # Index 0 - Archetype Instance Name

                # Getting defaults
                $archetypeInstanceName = `
                    $filters[0];
                
                # Let's create a directory string based on the 
                # formatted string from above ($this.mappingsDirectory)
                # Formatted string ($this.mappingsDirectory) contains slashes as 
                # delimiter
                $newMappingsDirectory = $this.mappingsDirectory -F `
                    $this.mappingContainerName, `
                    $archetypeInstanceName;

                # Let's generate a path that is OS agnostic
                $newMappingsDirectory = `
                    $this.NormalizeFilePath(
                        @($this.rootPath) + $newMappingsDirectory.Split('/'));

                # Let's add the file name and generate an absolute path
                # In this case, both are single strings, so is ok to 
                # create a single array @()
                $mappingsAbsolutePath = `
                    $this.NormalizeFilePath(
                        @($newMappingsDirectory, $this.mappingsFileName));

                # Let's check if the file exists
                $fileExists = Test-Path $mappingsAbsolutePath;

                # If file exists, open it and read its contents
                if ($fileExists) {
                    # Read the contents of the file, convert to JSON object
                    # and return the object
                    $contentJson = `
                        Get-Content $mappingsAbsolutePath `
                            -Raw `
                        | ConvertFrom-Json `
                            -AsHashtable `
                            -Depth 100;
                    return $contentJson.$archetypeInstanceName;
                }
                else {
                    # file was not found
                    return $null;
                }
            }
            else {
                Throw "Filters Argument must be of length 2";
            }
        }
        catch {
            Write-Host "An error ocurred while running LocalStorageAuditRepository.GetLatestDeploymentId";
            Write-Host $_;
            throw $_;
        }
    }

    hidden [void] CreateDirectory([string] $directory) {
        try {
            New-Item $directory `
                -ItemType 'Directory' `
                -Force;
        }
        catch {
            Write-Host "An error ocurred while running LocalStorageAuditRepository.SaveResourceState";
            Write-Host $_;
            throw $_;
        }
    }

    hidden [string] NormalizeFilePath([string[]] $filePathList) {
        try {
            $newFilePath = '';
            # Let's loop through all the items in the array
            # and combine the paths
            $filePathList `
            | ForEach-Object { 
                $newFilePath = `
                    [IO.Path]::Combine($newFilePath,$_);
            };
            return $newFilePath;
        }
        catch {
            Write-Host "An error ocurred while running LocalStorageAuditRepository.NormalizeFilePath";
            Write-Host $_;
            throw $_;
        }
    }
}
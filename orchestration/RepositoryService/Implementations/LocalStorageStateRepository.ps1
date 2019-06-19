
Class LocalStorageStateRepository: IStateRepository {

    $storageAccountContext = $null;
    $stateContainerName = "deployments";
    $mappingContainerName = "mappings";
    $rootPath = "";
    
    # stateDirectory has the following format
    # stateContainerName/archetypeInstanceName/moduleInstanceName/deploymentName
    $stateDirectory = "{0}/{1}/{2}/{3}";
    
    # stateFullPath has the following format
    # stateContainerName/archetypeInstanceName/moduleInstanceName/deploymentName/stateId.json
    $stateFileName = "{0}.json";
    
    # mappingsDirectory has the following format
    # mappingContainerName/archetypeInstanceName
    $mappingsDirectory = "{0}/{1}";

    # mappingContainerName/deploymentMappings.json
    $mappingsFileName = "deploymentMappings.json";

    LocalStorageStateRepository() {
        # TODO: Get value from cache
        $this.rootPath = `
            $ENV:vdc_localAuditPath;
    }

    [void] SaveResourceState([object] $entity) {
        
        # Getting defaults
        $archetypeInstanceName = `
            $entity.ArchetypeInstanceName;
        $moduleInstanceName = `
            $entity.ModuleInstanceName;
        $deploymentName = `
            $entity.DeploymentName;
        $stateId = `
            $entity.StateId;
        
        try {
            # Let's create a directory string based on the 
            # formatted string from above ($this.stateDirectory)
            # Formatted string ($this.stateDirectory) 
            # contains slashes as delimiter
            $newStateDirectory = $this.stateDirectory -F `
                $this.stateContainerName, `
                $archetypeInstanceName, `
                $moduleInstanceName, `
                $deploymentName;

            # Let's normalize the directory by passing a string
            # array, the result will be an OS specific directory
            # path
            $newStateDirectory = `
                $this.NormalizeFilePath(
                    $newStateDirectory.Split('/'));

            # Let's add the root path
            $newStateDirectory = `
                $this.NormalizeFilePath(
                    @($this.rootPath) + $newStateDirectory);

            # Let's create the directory
            $this.CreateDirectory($newStateDirectory);

            # Let's generate a file name
            $newStateFileName = $this.stateFileName -F `
                $stateId;

            # Let's add the file name and generate
            # an absolute path
            $stateAbsolutePath = `
                $this.NormalizeFilePath(
                    @($newStateDirectory) + $newStateFileName);
            
            # Let's save the file contents
            ConvertTo-Json $entity `
                -Depth 100 `
                -Compress > $stateAbsolutePath;
        }
        catch {
            Write-Host "An error ocurred while running LocalStorageStateRepository.SaveResourceState";
            Write-Host $_;
            throw $_;
        }
    }

    [void] SaveResourceStateAndDeploymentNameMapping ([object] $entity) {
        
        # Getting defaults
        $archetypeInstanceName = `
            $entity.ArchetypeInstanceName;
        $moduleInstanceName = `
            $entity.ModuleInstanceName;
        $deploymentName = `
            $entity.DeploymentName;
        $stateId = `
            $entity.StateId;
        
        # Let's create mapping contents object
        # this object contains a module instance
        # name and deployment id mapping
        $mappingsContent = @{
            $moduleInstanceName = @{
                DeploymentName = $deploymentName
                StateId = $stateId
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

            # Let's add the file name and generate an absolute path
            $mappingsAbsolutePath = `
                $this.NormalizeFilePath(
                    @($newMappingsDirectory) + $this.mappingsFileName);
            
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
                if ($mappingsJson.$moduleInstanceName) {
                    # Let's update the previous deploymentId
                    # and stateId values
                    $mappingsJson.$moduleInstanceName.DeploymentName = `
                        $deploymentName;
                    $mappingsJson.$moduleInstanceName.StateId = `
                        $stateId;
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

            # Let's save the file
            ConvertTo-Json $mappingsContent `
                -Depth 100 `
                -Compress > $mappingsAbsolutePath;
        }
        catch {
            Write-Host "An error ocurred while running LocalStorageStateRepository.SaveResourceStateAndDeploymentIdMapping";
            Write-Host $_;
            throw $_;
        }
    }

    [hashtable] GetResourceStateById([object] $id) {
        Throw "Method Not Implemented";
    }
    
    [hashtable] GetResourceStateByFilters([object[]] $filters) {
        
        try {
            if($filters.Count -ge 4) {
                # File name is derived from the filters array
                # $filters parameter assumes to contain the 
                # following information:
                # Index 0 - Archetype Instance Name
                # Index 1 - Module Instance Name
                # Index 2 - Deployment Name
                # Index 3 - State Id
                
                # Getting defaults
                $archetypeInstanceName = `
                    $filters[0];
                $moduleInstanceName = `
                    $filters[1];
                $deploymentName = `
                    $filters[2];
                $stateId = `
                    $filters[3];
                
                # Let's create a directory string based on the 
                # formatted string from above ($this.stateDirectory)
                # Formatted string ($this.stateDirectory) contains slashes as 
                # delimiter
                $newStateDirectory = $this.stateDirectory -F `
                    $this.stateContainerName, `
                    $archetypeInstanceName, `
                    $moduleInstanceName, `
                    $deploymentName;
            
                # Let's normalize the directory by passing a string
                # array, the result will be an OS specific directory
                # path
                $newStateDirectory = `
                    $this.NormalizeFilePath(
                        $newStateDirectory.Split('/'));
                
                # Let's generate a file name
                $newStateFileName = $this.stateFileName -F `
                    $stateId;

                # Let's add the file name and generate
                # an absolute path (single strings should
                # be converted into arrays)
                $stateAbsolutePath = `
                    $this.NormalizeFilePath(
                        @($this.rootPath) + $newStateDirectory + @($newStateFileName));
                
                # Let's check if the file exists
                $fileExists = Test-Path $stateAbsolutePath;
                
                # If file exists, retrieve data
                if($fileExists) {
                    # Read the contents of the file, convert to JSON object
                    # and return the object
                    $contentJson = `
                        Get-Content $stateAbsolutePath `
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
                throw "Filters Argument must be of length 4";
            }
        }
        catch {
            Write-Host "An error ocurred while running LocalStorageStateRepository.GetResourceStateByFilters";
            Write-Host $_;
            throw $_;
        }
    }

    [hashtable] GetLatestDeploymentMapping([object[]] $filters) {
        
        try {
            if($filters.Count -ge 2) {
                # blob name is derived from the filters array
                # filters array indexes are assumed to contain the following
                # information:
                # Index 0 - Archetype Instance Name
                # Index 1 - Module Instance Name

                # Getting defaults
                $archetypeInstanceName = `
                    $filters[0];
                $moduleInstanceName = `
                    $filters[1];
                
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
                
                # If file exists, retrieve data
                if($fileExists) {
                    # Read the contents of the file, convert to JSON object
                    # and return the object
                    $contentJson = `
                        Get-Content $mappingsAbsolutePath `
                            -Raw `
                        | ConvertFrom-Json `
                            -AsHashtable `
                            -Depth 100;
                    return $contentJson.$moduleInstanceName;
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
            Write-Host "An error ocurred while running LocalStorageStateRepository.GetLatestDeploymentId";
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

Class BlobContainerStateRepository: IStateRepository {

    $storageAccountContext = $null;
    $stateBlobContainerName = 'deployments';
    $mappingsBlobContainerName = 'mappings';
    $temporalRootPath = '';
    # stateBlobPath has the following format
    # stateBlobContainerName/deployments/archetypeInstanceName/moduleInstanceName/deploymentName/stateId.json
    $stateBlobPath = '{0}/{1}/{2}/{3}.json';
    # mappingsBlobPath has the following format
    # archetypeInstanceName/mappings.json
    $mappingsBlobPath = '{0}/deploymentMappings.json';

    BlobContainerStateRepository([string]$storageAccountName, 
                                 [string]$storageAccountSasToken) {
        # Getting HOME path environment variable
        $this.temporalRootPath = `
            (Get-ChildItem -Path Env:HOME -ErrorAction SilentlyContinue).Value;

        if ($null -eq $this.temporalRootPath) {
            # Attempt to retrieve a LOCALAPPDATA Environment variable
            $this.temporalRootPath = `
                (Get-ChildItem -Path Env:LOCALAPPDATA -ErrorAction SilentlyContinue).Value;
        }

        if ($null -eq $this.temporalRootPath) {
            # No Home or Local app data variables found,
            # let's resolve a default path.
            $this.temporalRootPath = `
                Resolve-Path ".\";
        }
        
        # Let's create a storage account context
        # this will be used to manipulate the
        # different containers
        $this.storageAccountContext = `
            New-AzStorageContext `
            -StorageAccountName $storageAccountName `
            -SasToken $storageAccountSasToken
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
        
        # Let's create a blob name
        $blobName = $this.stateBlobPath -F `
            $archetypeInstanceName, `
            $moduleInstanceName, `
            $deploymentName, `
            $stateId

        # Create a temporal file path to store the state contents
        $temporalFileName = [Guid]::NewGuid();
        $temporalFilePath = `
            Join-Path $this.temporalRootPath "$temporalFileName.json";

        try {

            # Let's create the file contents temporally
            ConvertTo-Json $entity `
                -Depth 100 `
                -Compress > $temporalFilePath;
            
            # Upload the file to the storage account
            Set-AzStorageblobcontent `
                -File $temporalFilePath `
                -Container $this.stateBlobContainerName `
                -Blob $blobName `
                -Context $this.storageAccountContext;
        }
        catch {
            Write-Host "An error ocurred while running ModuleStateDataService.SaveResourceState";
            Write-Host $_;
            throw $_;
        }
        finally {
            # ErrorAction is set to SilentlyContinue because the Cmdlet
            # errors out if the Path is not found
            Remove-Item -Path $temporalFilePath -ErrorAction SilentlyContinue;
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
        
        # Creates a blob name
        $blobName = $this.mappingsBlobPath -F `
            $archetypeInstanceName;

        # Creates a temporal file path to store 
        # the mapping contents
        $temporalFileName = [Guid]::NewGuid();
        $temporalFilePath = `
            Join-Path $this.temporalRootPath "$temporalFileName.json";
        
        try {
            # Let's check if the blob exists
            $blobExists = $this.BlobExists(
                $this.mappingsBlobContainerName, 
                $blobName);
            Write-Debug "Container name: $($this.mappingsBlobContainerName) and blob name: $blobName";
            # Set the initial value equals to the 
            # mappingsContent from above, this allows
            # us to save the initial contents when a 
            # blob content is empty.
            $mappingsJson = $mappingsContent;
            
            # A non-empty value indicates that a blob exists
            if (![string]::IsNullOrEmpty($blobExists)) {
                # Convert the data downloaded to hashtable 
                $mappingsJson = `
                    ConvertFrom-Json $blobExists `
                        -AsHashTable;
                # Let's get the moduleInstanceName object.
                # The returned value will contain the resource mapping information,
                # otherwise a $null value is returned
                $mapping = `
                    $mappingsJson.$moduleInstanceName;
                
                # If a value does not exists,
                # append $mappingsContent to the existing
                # blob contents ($mappingsJson)
                if ($mapping -eq $null) {
                    $mappingsJson += $mappingsContent;
                } 
                else {
                    # Let's update the previous deploymentId
                    # and stateId values
                    $mappingsJson.$moduleInstanceName.DeploymentName = `
                        $deploymentName;
                    $mappingsJson.$moduleInstanceName.StateId = `
                        $stateId;
                }
            }

            # Let's create the file contents temporally
            ConvertTo-Json $mappingsJson `
                -Depth 100 `
                -Compress > $temporalFilePath;
        
            # Upload the file and overwrite (if exists) the  
            # blob in the storage account
            Set-AzStorageblobcontent -File $temporalFilePath `
                -Container $this.mappingsBlobContainerName `
                -Blob $blobName `
                -Context $this.storageAccountContext `
                -Force;
        }
        catch {
            Write-Host "An error ocurred while running ModuleStateDataService.SaveResourceStateAndDeploymentIdMapping";
            Write-Host $_;
            throw $_;
        }
        finally {
            Remove-Item -Path $temporalFilePath -ErrorAction SilentlyContinue;
        }
    }

    [object] GetResourceStateById([object] $id) {
        Throw "Method Not Implemented";
    }
    
    [hashtable] GetResourceStateByFilters([object[]] $filters) {
        
        # set the temporary file path for downloading the file
        $temporalFileName = [Guid]::NewGuid();
        $temporalFilePath = `
            Join-Path $this.temporalRootPath "$temporalFileName.json";
        
        try {
            if($filters.Count -ge 4) {
                # Blob name is derived from the filters array
                # $filters parameter assumes to contain the 
                # following information:
                # Index 0 - Archetype Instance Name
                # Index 1 - Module Instance Name
                # Index 2 - Deployment Id
                # Index 3 - State Id
                
                # Getting defaults
                $archetypeInstanceName = `
                    $filters[0];
                $moduleInstanceName = `
                    $filters[1];
                $deploymentId = `
                    $filters[2];
                $stateId = `
                    $filters[3];
                
                $blobName = $this.stateBlobPath -F `
                    $archetypeInstanceName, `
                    $moduleInstanceName, `
                    $deploymentId, `
                    $stateId;
                
                # Let's check if the blob exists, if it does,
                # this function will return the blob contents
                $blobFound = $this.BlobExists(
                    $this.stateBlobContainerName, 
                    $blobName);
                
                Write-Debug "Blob container: $($this.stateBlobContainerName), Blob Name: $blobName";
            
                # A non-empty value indicates that a blob exists
                if (![string]::IsNullOrEmpty($blobFound)) {
                    return ConvertFrom-Json $blobFound -AsHashtable;
                }
                else {
                    # blob was not found
                    return $null;
                }
            }
            else {
                throw "Filters Argument must be of length 4";
            }
        }
        catch {
            Write-Host "An error ocurred while running ModuleStateDataService.GetResourceStateByFilters";
            Write-Host $_;
            throw $_;
        }
    }

    [hashtable] GetLatestDeploymentMapping([object[]] $filters) {
        
        # set the temporary file path for downloading the file
        $temporalFileName = [Guid]::NewGuid();
        $temporalFilePath = `
            Join-Path $this.temporalRootPath "$temporalFileName.json";
        
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
                Write-Debug "archetypeInstanceName: $archetypeInstanceName, moduleInstanceName: $moduleInstanceName";
                
                $blobName = $this.mappingsBlobPath -F `
                    $archetypeInstanceName;
                
                Write-Debug "Blob container: $($this.mappingsBlobContainerName), Blob Name: $blobName";
            
                # Let's check if the blob exists, if it does,
                # this function will return the blob contents
                $blobFound = $this.BlobExists(
                    $this.mappingsBlobContainerName, 
                    $blobName);
                
                # A non-empty value indicates that a blob exists
                if (![string]::IsNullOrEmpty($blobFound)) {
                    return `
                        (ConvertFrom-Json $blobFound `
                            -AsHashTable).$moduleInstanceName;
                }
                else {
                    Write-Debug "Blob not found"
                    # blob was not found
                    return $null;
                }
            }
            else {
                Throw "Filters Argument must be of length 2";
            }
        }
        catch {
            Write-Host "An error ocurred while running ModuleStateDataService.GetLatestDeploymentId";
            Write-Host $_;
            throw $_;
        }
        finally {
            Remove-Item -Path $temporalFilePath -ErrorAction SilentlyContinue;
        }
    }

    hidden [string] BlobExists([string] $container, 
                               [string] $blob) {
                                
        Write-Debug "About to retrieve Container: $container and Blob: $blob"
        $temporalFileName = [Guid]::NewGuid();
        $temporalFilePath = `
            Join-Path $this.temporalRootPath "$temporalFileName.json";
        Write-Debug "Temporal file path: $temporalFilePath"
        try {
            $blobFound = Get-AzStorageBlobContent `
                -Container $container `
                -Blob $blob `
                -Destination $temporalFilePath `
                -Context $this.storageAccountContext `
                -ErrorAction SilentlyContinue
            
            if ($null -eq $blobFound) {
                Write-Debug "No blob found"
                return "";
            }
            else {
                $contentJson = `
                    Get-Content $temporalFilePath `
                        -Raw;
                Write-Debug "Blob found: $contentJson"
                return $contentJson;
            }
        }
        catch {
            Write-Host "An error ocurred while running ModuleStateDataService.BlobExists";
            Write-Host $_;
            throw $_;
        }
        finally {
            Remove-Item -Path $temporalFilePath -ErrorAction SilentlyContinue;
        }
    }
}
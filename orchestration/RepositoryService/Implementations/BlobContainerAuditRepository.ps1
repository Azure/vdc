Class BlobContainerAuditRepository: IAuditRepository {

    $storageAccountContext = $null;
    $auditBlobContainerName = 'audit';
    $mappingsBlobContainerName = 'mappings';
    $temporalRootPath = '';
    # auditBlob has the following format
    # archetypeInstanceName/auditId.json
    $auditBlobPath = '{0}/{1}.json';
    $mappingsBlobPath = '{0}/auditMappings.json';

    BlobContainerAuditRepository([string]$storageAccountName, 
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

    # Entity is a wrapper around the collection of data
    # that is being stored in the repository
    [void] SaveAuditTrail([object] $entity) {

        # Getting defaults
        $archetypeInstanceName = `
            $entity.ArchetypeInstanceName; 
        $auditId = `
            $entity.AuditId;

        # Let's create a blob name
        $blobName = $this.auditBlobPath -F `
            $archetypeInstanceName, `
            $auditId;
        
        # Create a temporal file path to store the state contents
        $temporalFileName = [Guid]::NewGuid();
        $temporalFilePath = `
            Join-Path $this.temporalRootPath "$temporalFileName.json"
        Write-Host "TemporalFilePath is: $temporalFilePath";
        try {

             # Let's create the file contents temporally
             ConvertTo-Json $entity `
                -Depth 100 `
                -Compress > $temporalFilePath;
         
            # Upload the file to the storage account
            Set-AzStorageblobcontent `
                -File $temporalFilePath `
                -Container $this.auditBlobContainerName `
                -Blob $blobName `
                -Context $this.storageAccountContext;
        }
        catch {
            Write-Host "An error ocurred while running BlobContainerAuditRepository.SaveAuditTrail";
            Write-Host $_;
            throw $_;
        }
        finally {
            # ErrorAction is set to SilentlyContinue because the Cmdlet
            # errors out if the Path is not found
            Remove-Item -Path $temporalFilePath -ErrorAction SilentlyContinue;
        }
    }

    [void] SaveAuditTrailAndDeploymentIdMapping([object] $entity) {
        # Getting defaults
        $archetypeInstanceName = `
            $entity.ArchetypeInstanceName;
        $moduleInstanceName = `
            $entity.ModuleInstanceName;
        $deploymentId = `
            $entity.DeploymentId;
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
        
        # Creates a blob name
        $blobName = $this.mappingsBlobPath -F `
            $archetypeInstanceName;

        # Creates a temporal file path to store 
        # the mapping contents
        $temporalFileName = [Guid]::NewGuid();
        $temporalFilePath = `
            Join-Path $this.temporalRootPath "$temporalFileName.json";
        
        try {
            # Let's check if the blob exists, if it does,
            # this function will return the blob contents
            $blobExists = $this.BlobExists(
                $this.mappingsBlobContainerName, 
                $blobName);

            Write-Host "Container name: $($this.mappingsBlobContainerName) and blob name: $blobName";
            
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
            Write-Host "An error ocurred while running BlobContainerAuditRepository.SaveAuditTrailAndDeploymentMapping";
            Write-Host $_;
            throw $_;
        }
        finally {
            Remove-Item -Path $temporalFilePath -ErrorAction SilentlyContinue;
        }
    }

    [void] GetAuditTrailByCommitId ([object] $commitId) {
        Throw "Method Not Implemented";
    }

    [hashtable] GetAuditTrailByFilters([array] $filters) {

        try {
            if($filters.Count -ge 2) {
                # Blob name is derived from the filters array
                # $filters parameter assumes to contain the 
                # following information:
                # Index 0 - Archetype Instance Name
                # Index 1 - Audit Id

                # Getting defaults
                $archetypeInstanceName = `
                    $filters[0];
                $auditId = `
                    $filters[1];
                
                # Let's construct the blob name
                $blobName = $this.auditBlobPath -F `
                    $archetypeInstanceName, `
                    $auditId;
                
                # Let's check if the blob exists, if it does,
                # this function will return the blob contents
                $blobFound = $this.BlobExists(
                    $this.auditBlobContainerName, 
                    $blobName);
                
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
                throw "Filters Argument must be of length 2";
            }
        }
        catch {
            Write-Host "An error ocurred while running BlobContainerAuditRepository.GetAuditTrailById";
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

    [string] GetLatestAuditMapping([object[]] $filters) {
        
        try {
            if($filters.Count -ge 2) {
                # Blob name is derived from the filters array
                # $filters parameter assumes to contain the 
                # following information:
                # Index 0 - Archetype Instance Name
                # Index 1 - Module Instance Name

                # Getting defaults
                $archetypeInstanceName = `
                    $filters[0];
                
                # Let's create the blob name
                $blobName = $this.mappingsBlobPath -F `
                    $archetypeInstanceName;
    
                # Let's check if the blob exists, if it does,
                # this function will return the blob contents
                $blobFound = $this.BlobExists(
                    $this.auditBlobContainerName, 
                    $blobName);
                
                # A non-empty value indicates that a blob exists
                if(![string]::IsNullOrEmpty($blobFound)) {
                    return (ConvertFrom-Json $blobFound `
                        -AsHashTable).$archetypeInstanceName;
                }
                else {
                    # blob was not found
                    return $null;
                }
            }
            else {
                Throw "Filters Argument must be of length 2";
            }
        }
        catch {
            Write-Host "An error ocurred while running BlobContainerAuditRepository.GetLatestDeploymentId";
            Write-Host $_;
            throw $_;
        }
    }

    hidden [string] BlobExists([string] $container, 
                               [string] $blob) {
        
        $temporalFileName = [Guid]::NewGuid();
        $temporalFilePath = `
            Join-Path $this.temporalRootPath "$temporalFileName.json";
        Write-Host "Temporal File Path is $temporalFilePath";
        
        try {
            $blobFound = Get-AzStorageBlobContent `
                -Container $container `
                -Blob $blob `
                -Destination $temporalFilePath `
                -Context $this.storageAccountContext `
                -ErrorAction SilentlyContinue;
            
            if ($blobFound -eq $null) {
                Write-Host "Blob not found";
                return "";
            }
            else {
                $contentJson = `
                    Get-Content $temporalFilePath `
                        -Raw;
                Write-Host "Content Json is $contentJson";
                return $contentJson;
            }
        }
        catch {
            Write-Host "An error ocurred while running BlobContainerAuditRepository.BlobExists";
            Write-Host $_;
            throw $_;
        }
        finally {
            Remove-Item -Path $temporalFilePath -ErrorAction SilentlyContinue;
        }
    }
}
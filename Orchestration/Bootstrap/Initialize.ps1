Class Initialize {
    [string]$dataStoreSubscriptionId = '';
    [string]$dataStoreTenantId = '';
    [string]$dataStoreResourceGroupName = 'vdc-storage-rg';
    [string]$dataStoreName = 'vdcDataStore';
    [string]$dataStoreLocation = 'westus';
    # This array indicates the folders/containers/tables/collections
    # to be created inside of VDC Data Store
    $dataStoreSubFolders = @(
        @{  
            Name = "deployments"
            IsImmutable = $true 
        },
        @{  
            Name = "audit" 
            IsImmutable = $true 
        },
        @{ 
            Name = "mappings"
            IsImmutable = $false 
        }
    );
    
    Initialize() {
        # Persist the Az Context so that any PSSession jobs can
        # access and run Az Cmdlets. This assumes the user has 
        # already logged in.
        Enable-AzContextAutosave;
    }

    # Function that creates a data store used to
    # store resource state and audit information.
    # This function assumes default values specified on the top
    [string] InitializeLocalStore() {
        return $this.createLocalFileDataStore();
    }

    # Function that creates a data store used to
    # store resource state and audit information
    [hashtable] InitializeStorageAccountStore( [string]$dataStoreTenantId,
                    [string]$dataStoreSubscriptionId,
                    [string]$dataStoreResourceGroupName='',
                    [string]$dataStoreLocation='',
                    [string]$dataStoreName='') {
        $this.dataStoreTenantId = `
            $dataStoreTenantId;
        $this.dataStoreSubscriptionId = `
            $dataStoreSubscriptionId;
        $this.dataStoreResourceGroupName = `
            $dataStoreResourceGroupName;
        $this.dataStoreLocation = `
            $dataStoreLocation;
        $this.dataStoreName = `
            $dataStoreName;
        return $this.createStorageAccountDataStore();
    }

    hidden [string] CreateLocalFileDataStore(){
        
        # Getting HOME path environment variable
        $homePath = Get-ChildItem -Path Env:HOME;

        $homePath = `
            (Get-ChildItem -Path Env:HOME -ErrorAction SilentlyContinue).Value;
        
        if ($null -eq $homePath) {
            # Attempt to retrieve a LOCALAPPDATA Environment variable
            $homePath = `
                (Get-ChildItem -Path Env:LOCALAPPDATA -ErrorAction SilentlyContinue).Value;
        }

        if ($null -eq $homePath) {
            # No Home or Local app data variables found,
            # let's resolve a default path.
            $homePath = `
                Resolve-Path ".\";
        }

        Write-Host "Local audit and state folder is: $homePath";
        
        # Creating a vdc data store path
        $vdcDataStorePath = `
            Join-Path -Path $homePath -ChildPath $this.dataStoreName;
        
        # Check for directory existence, if directory does not exist, create it
        $mainFolderExists = Test-Path $vdcDataStorePath;
        if ($mainFolderExists -eq $false){
            # Create a main local folder
            New-Item -ItemType "directory" -Path $vdcDataStorePath;
            
            # Create sub folders, these folders will store resource deployment information 
            # and its state
            foreach($subFolder in $this.dataStoreSubFolders) {
                $subFolderPath = Join-Path -Path $vdcDataStorePath -ChildPath $subFolder.Name;
                
                # Check for directory existence, if directory does not exist, create it
                $subFolderExists = Test-Path $subFolderPath;
                if($subFolderExists -eq $false){
                    New-Item -ItemType "directory" -Path $subFolderPath;
                }
            }
        }
        Write-Host "Bootstrap process completed successfully";
        return $vdcDataStorePath;
    }

    hidden [hashtable] CreateStorageAccountDataStore(){
        try {
            if ($this.dataStoreName -eq '') {
                $storageAccountName = "$($this.dataStoreTenantId)-$($this.dataStoreSubscriptionId)"
                $this.dataStoreName = Get-UniqueString($storageAccountName);
                Write-Host "Storage Account Name: $($this.dataStoreName)"
            } else {
                # If a value is passed, make sure to use ToLower, any other Storage
                # account name validations are not performed in this function
                $this.dataStoreName = $this.dataStoreName.ToLower();
            }
    
            Set-AzContext `
                -Tenant $this.dataStoreTenantId `
                -Subscription $this.dataStoreSubscriptionId

            $storageResourceGroup = Get-AzResourceGroup `
                -Name $this.dataStoreResourceGroupName `
                -ErrorAction SilentlyContinue;

            if($null -eq $storageResourceGroup) {
                # Create a storage account resource group
                New-AzResourceGroup -Name $this.dataStoreResourceGroupName `
                                    -Location $this.dataStoreLocation `
                                    -Force;
            }
             
            $storageAccountExists = `
                !(Get-AzStorageAccountNameAvailability -Name $this.dataStoreName).NameAvailable
            Write-Host "Storage Account Exists: $storageAccountExists"
            
            if ($storageAccountExists -eq $false) {
                # Creates a storage account
                New-AzStorageAccount `
                -ResourceGroupName $this.dataStoreResourceGroupName `
                -Name $this.dataStoreName `
                -Location $this.dataStoreLocation `
                -EnableHttpsTrafficOnly $true `
                -Tag @{ 'layer' = 'audit' } `
                -SkuName "Standard_GRS" `
                -Kind "StorageV2";
             }
            
             # Create containers
             $this.dataStoreSubFolders | ForEach-Object { 

                # Check if the container exists before attempting
                # to create one
                $container = Get-AzRmStorageContainer `
                    -ResourceGroupName $this.dataStoreResourceGroupName `
                    -StorageAccountName $this.dataStoreName `
                    -ContainerName $_.Name `
                    -ErrorAction SilentlyContinue;

                if($null -eq $container) {
                    New-AzRmStorageContainer `
                    -Name $_.Name `
                    -ResourceGroupName $this.dataStoreResourceGroupName `
                    -StorageAccountName $this.dataStoreName;
                    
                    if ($_.IsImmutable) {
                        # Enable immutable storage
                        Add-AzRmStorageContainerLegalHold `
                            -ResourceGroupName $this.dataStoreResourceGroupName `
                            -StorageAccountName $this.dataStoreName `
                            -ContainerName $_.Name `
                            -Tag "audit";
                    }
                }
            }

            $storageAccountAccessKey = `
                (Get-AzStorageAccountKey `
                    -ResourceGroupName $this.dataStoreResourceGroupName `
                    -Name $this.dataStoreName).Value[0];
            
            $storageAccountContext = `
                New-AzStorageContext `
                    -StorageAccountName $this.dataStoreName `
                    -StorageAccountKey $storageAccountAccessKey;
            
            # Set SAS Token expiration of 2 hours
            $twoHoursDuration = New-TimeSpan -Hours 2;
            $expiryTime = (Get-Date) + $twoHoursDuration;

            # SAS Token permission does not have any delete or update permissions
            $sasToken = `
                New-AzStorageAccountSASToken `
                    -Service Blob,Table `
                    -ResourceType Service,Container,Object `
                    -Permission "racwl" `
                    -Protocol HttpsOnly `
                    -ExpiryTime $expiryTime `
                    -Context $storageAccountContext;

            Write-Host "Bootstrap process completed successfully";

            return @{
                StorageAccountName = $this.dataStoreName
                StorageAccountResourceGroup = $this.dataStoreResourceGroupName
                StorageAccountSasToken = $sasToken
            }
        }
        catch {
            Write-Host "An error ocurred while running VDC Bootstrap";
            Write-Host $_;
            throw $_;
        }
    }

    hidden [void] CreateCosmosDBDataStore(){
        
    }
}
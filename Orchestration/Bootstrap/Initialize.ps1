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

            $cachedStorageAccountDetails = `
                Get-PowershellEnvironmentVariable `
                    -Key "BOOTSTRAP_INITIALIZED";
            Write-Debug "Storage Account details found: $cachedStorageAccountDetails";

            if ($null -eq $cachedStorageAccountDetails){
                $validJson = $false;
            }
            else {
                $validJson = `
                    Test-JsonContent $cachedStorageAccountDetails;
                Write-Debug "Is valid JSON: $validJson";
            }

            $storageAccountDetails = $null;

            if ([string]::IsNullOrEmpty($cachedStorageAccountDetails) -or 
                !$validJson) {
                Write-Debug "No valid JSON found, running Storage Account bootstrap";

                # Setting context in order to create / verify the toolkit
                # resource group and storage account resource
                Set-AzContext `
                    -Tenant $this.dataStoreTenantId `
                    -Subscription $this.dataStoreSubscriptionId;

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

                $sasToken = `
                        $this.GetSASToken(
                            $this.dataStoreName,
                            $this.dataStoreResourceGroupName);

                $storageAccountDetails = @{
                    StorageAccountName = $this.dataStoreName
                    StorageAccountResourceGroup = $this.dataStoreResourceGroupName
                    StorageAccountSasToken = $sasToken.SASToken
                    ExpiryTime = $sasToken.ExpiryTime
                }
            }
            elseif($validJson) {
                $storageAccountDetails = `
                    ConvertFrom-Json $cachedStorageAccountDetails `
                    -AsHashtable;
                
                $oneHourDuration = New-TimeSpan -Hours 1;

                # Let's check if the life of the sas token expires within an hour
                # if it does, let's get a new sas token
                if(($storageAccountDetails.ExpiryTime - (Get-Date)) -le $oneHourDuration) {
                    
                    Write-Debug "Obtaining new SAS Token, previous expired"

                    # Setting AZ context to be able to retrieve the proper
                    # SAS token, there are situations where the toolkit
                    # subscription is different than the one from the
                    # archetype deployment 
                    Set-AzContext `
                        -Tenant $this.dataStoreTenantId `
                        -Subscription $this.dataStoreSubscriptionId;
                    
                    
                    $sasToken = `
                        $this.GetSASToken(
                            $this.dataStoreName,
                            $this.dataStoreResourceGroupName);

                    Write-Debug "Sas token acquired, new expiriy time is: $($storageAccountDetails.ExpiryTime)"
                    $storageAccountDetails.StorageAccountSasToken = `
                        $sasToken.SASToken;
                    $storageAccountDetails.ExpiryTime = `
                        $sasToken.ExpiryTime;
                }
            }
            else {
                Throw "Could not retrieve the Storage Account Access Keys. Please `
                make sure you have logged in using 'Login-AzAccount' and you have
                the correct subscription and tenant id in the toolkit subscription json";
            }
            # Let's set the storage account details as an environment variable.
            # For this variable to be shared across different agents, make sure to
            # create an Azure DevOps pipeline variable (or a variable in a variable
            # group) with the name BOOTSTRAP_INITIALIZED and set it to empty.
            # In a local deployment, this value will be set only once 
            # and the code will check if the token  expires within an hour, if it does
            # the code creates a new SAS Token.
            $storageAccountDetailsJson = `
                (ConvertTo-Json $storageAccountDetails -Compress);

            # Local syntax to set a variable
            $ENV:BOOTSTRAP_INITIALIZED = $storageAccountDetailsJson;

            # Azure DevOps syntax to set a pipeline variable
            Write-Host "##vso[task.setvariable variable=BOOTSTRAP_INITIALIZED]$storageAccountDetailsJson";
            Write-Host "Bootstrap process completed successfully";
            return $storageAccountDetails;
        }
        catch {
            Write-Host "An error ocurred while running VDC Bootstrap";
            Write-Host $_;
            throw $_;
        }
    }

    hidden [hashtable] GetSASToken(
        [string] $storageAccountName,
        [string] $storageAccountResourceGroup) {
        try {

            Write-Host "Creating a storage account: $storageAccountName in resource group: $storageAccountResourceGroup"
            $storageAccountAccessKey = $null;

            $storageAccountAccessKeys = `
                (Get-AzStorageAccountKey `
                    -ResourceGroupName $this.dataStoreResourceGroupName `
                    -Name $this.dataStoreName).Value;

            # Set SAS Token expiration of 2 hours
            $twoHoursDuration = New-TimeSpan -Hours 3;
            $expiryTime = (Get-Date) + $twoHoursDuration;

            if($null -ne $storageAccountAccessKeys) {
                Write-Host "Keys acquired successfully"
                $storageAccountAccessKey = `
                    $storageAccountAccessKeys[0];
            
                $storageAccountContext = `
                    New-AzStorageContext `
                        -StorageAccountName $this.dataStoreName `
                        -StorageAccountKey $storageAccountAccessKey;
                
                # SAS Token permission does not have any delete or update permissions
                $sasToken = `
                    New-AzStorageAccountSASToken `
                        -Service Blob,Table `
                        -ResourceType Service,Container,Object `
                        -Permission "racwl" `
                        -Protocol HttpsOnly `
                        -ExpiryTime $expiryTime `
                        -Context $storageAccountContext;
            }
            else {
                throw "Invalid Storage Account Access key found";
            }
            
            return @{ 
                SASToken = $sasToken
                ExpiryTime = $expiryTime
            }
        }
        catch {
            Write-Host "An error ocurred while running VDC Bootstrap.GetSASToken";
            Write-Host $_;
            throw $_;
        }
    }

    hidden [void] CreateCosmosDBDataStore(){
        
    }
}
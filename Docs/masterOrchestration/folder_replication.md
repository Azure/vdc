## Environment Folder Replication 
1. Copy the SharedServices or MS-VDI folders however many times you want to deploy those environments
    - Within the MS-VDI folders you will need to change the following lines per folder copy or per spoke environment
		- **Parameters.json** for ms-vdi
		    1. Make sure the folder name is unique 
                1. Ex: "MS-VDI-SPOKE-2"
			2. Change line 2: Deployment name (unique)
			3. Change line 29: VNET spoke address prefix
			4. Change line 47: VNET spoke address prefix
			
2. If you are going to be deploying multiple "Shared Services" environments you will need to utilize:  
	a. [Shared Services SPOKE](../../Environments/SharedServices-SPOKE) folder in the environment directory  
	b. This folder has the necessary changes for deploying multiple iterations of shared services.  
	c. Copy this folder however many times you need to deploy shared services.  

**For any resources you do not want to deploy you must add the following to the Orchestration.JSON file**  
	- "Enabled": false,

This will ensure the resource is not deployed for the environment. This applies to any folder under "environments"


![](/images/orchestration_enable.png)
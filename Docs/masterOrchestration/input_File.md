## Setting up the inputFile.JSON for the master orchestration script

The inputFile.json should be placed in an accessible folder so that the MasterOrchestration script can retrieve it for manipulation.

An example of the input file: [Input File Example](../../inputFile.json)

The deployment admin will need to set the following values (example below in Picture 1):
1. Tenant ID
2. azureEnvironmentName 
3. organizationName
4. azureDiscoveryURL
5. azureSentinel

![Picture 1](/images/input_file_ex.png)
*Picture 1*

**NOTE: DO NOT CHANGE  "SharedServices" (In the example picture 2 below its line 8)**  
**NOTE: DO NOT CHANGE the name iterations of "Hub1" (In the example picture 2 example below its line 10, 22)**
- The objects under "SharedServices" represent the shared services deployments 
- NOTE: The first object ("Hub1") under shared services will act as the hub for the VDC toolkit. All other environments will be peered with this hub for a true hub and spoke topology.
- In the example below there are two shared service deployments. 
    - Hub1 will be the hub for the VDC toolkit
	- Hub2 will be a shared services spoke for the VDC toolkit  
	    - In this case the Deployment admin will have to manipulate the shared services folders 
- There is no limit to the number of shared service environments you can deploy
- IF your organization only needs 1 Shared Services environment delete the second "hub2"

The deployment admin should change the following values under each Shared Service 
1. SubscriptionID
2. Location
3. keyVaultObjectID
4. devOpsID
5. adminSSHPubKey
6. vmAdminUserName
7. folderName
    1. This is the copied folder of the shared services

![Picture 2](/images/input_file_ex2.png)
*Picture 2*

After the shared services configuration is complete the deployment admin should change the MSVDI variables

DO NOT CHANGE Line 34 in the picture 3 below. This value "MSVDI" represents the msvdi deployments
NOTE: if you wish to add more spokes you must use the value iteration below
- "MSVDI1" Line 36
- "MSVDI2" Line 48
- And so on "MSVDI3"

![Picture 3](/images/input_file_ex3.png)  
*Picture 3*



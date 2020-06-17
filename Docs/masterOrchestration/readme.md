## Master Orchestration Overview
#### The master orchestration script is used to deploy multiple environments by executing only one script.

Two environment types exist with v1 of the master orchestration script
- "Shared Services" - located [SharedServices](../../Environments/SharedServices)
- "MS-VDI" - located [MS-VDI](../../Environments/MS-VDI)

The topology for the VDC toolkit is a hub and spoke model. The "shared services" environment(s) act as the hub and the "ms-vdi" environment(s) act as the 
spokes. 

The "Shared Services" environment can be broken down into multiple "shared service" environments if necessary. For example, if an organization wanted to split up the 
Active Directory components into a separate VNET and peer to the hub that can be done with the master orchestration script. 
Note: For testing purposes we suggest using one hub to begin and multiple spokes

The "MS-VDI" environment can be replicated 'X' number of times for the orchestration. Each spoke MS-VDI environment will be peered to the "Shared Services" or HUB environment.
Refer to the [folder_Replication](../masterOrchestration/folder_replication.md) for more information on how to create multiple spoke "MS-VDI" environments.

The master orchestration script has 3 prerequisites before the deployment admin can execute the script.
1. [Folder Replication](../masterOrchestration/folder_replication.md) 
2. [Input File](../masterOrchestration/input_File.md)
3. [Master Orchestration Script](../masterOrchestration_script.md)

Once these 3 requirements are satified the deployment admin can execute the master orchestration script to deploy the full VDC environment. 

#### TearDown Environment 

Please refer to the [Tear Down Document](../masterOrchestration/tearDownEnvironment.md) when destroying an environment.
The teardown feature will remove individual environments. 
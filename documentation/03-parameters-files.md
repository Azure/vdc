# Configuration files (archetype.json)

Configuration file for a deployment contains most of the important
settings needed for deploying shared services or workloads and are the primary files you
will need to edit. Before running deployment automation scripts, review and
update the parameters in these files to match your organization's settings.

Configuration files are found in the following locations:

| **Sample Deployment**          | **Configuration file location**    |
|-----------------------------|-----------------------------|
|Simulated on-premises |[archetypes/on-premises/archetype.test.json](../archetypes/on-premises/archetype.test.json)|
| shared-services |[archetypes/shared-services/archetype.test.json](../archetypes/shared-services/archetype.test.json)|
| paas |[archetypes/paas/archetype.test.json](../archetypes/paas/archetype.test.json)|
| iaas |[archetypes/iaas/archetype.test.json](../archetypes/iaas/archetype.test.json)|
| cloudbreak |[archetypes/cloudbreak/archetype.test.json](../archetypes/cloudbreak/archetype.test.json)|
| sap-hana |[archetypes/sap-hana/archetype.test.json](../archetypes/sap-hana/archetype.test.json)|


The settings in these files are broken into sections. The deployment parameters
files each have a group of "general" parameters that get used in both types of
deployments. Shared services configuration file also contain the "shared-services" group needed to create
Shared services resources. Workload parameters files have both a "shared-services" section with references
to resources that are created as part of the shared services deployment, and "workload"
parameters that apply to the resources deployed for the workload itself.

## Creating configuration files

**Important note:** *These configuration.**test**.json* files are not the actual files your deployments will use. The test versions of these files are a starting example and used as part of [integration testing](../12-integration-testing.md).

During your initial setup and preparation for any of the sample deployment types, you will need to make a copy of the sample test file and rename it *archetype.json*. This file should remain in the same folder as the copied test file. 

The archetype.json file is where you will enter your subscription, tenant, organizational, and VDC configuration information. Do not modify or delete the test file, as the values defined there are required to support integration testing.

Because they contain potentially sensitive information such as subscription IDs and user names, the default VDC Automation Toolkit [.gitignore](../.gitignore) file is set to prevent your deployment archetype.json files from being pushed to your code repository. Other users are expected to create their own versions of these files using the copy process noted above.

## Referencing parameters 

VDC Automation allows you to make use of values defined elsewhere in the shared services or workload deployment configuration file to set other parameters' values. This is done by referencing parameter values using the following format: ${parameter variable}

As an example, in a parameters file's module dependency section you can pull the organization name and shared-services deployment name from a shared services configuration file into a module's custom "resource-group-name" parameter value like this:

> "resource-group-name": "${general.organization-name}-${shared-services.deployment-name}-net-rg",

So in this case, if your parameter file defines you organization name as "contoso" and your shared-services deployment name as "hub001", the deployment script will set the resource-group-name to "contoso-hub001-net-rg" when it is executed.

## Referencing command line arguments

You can also reference values passed as arguments when the deployment script is executed. These are referred to as environment variables and are referenced using the following format: ${ENV:[variable-name]}. These variables are used in the same manner as parameter references. 

The toolkit currently supports referencing the following arguments in parameters files:

| Argument | Description | Variable Reference |
|----------|-------------|--------------------|
| {environment type} | Environment (shared-services, workload, on-premises). | ${ENV:ENVIRONMENT-TYPE} |
| -m | Resource module being deployed (ops, net, etc...). If no value is passed, then environment variable is null. | ${ENV:RESOURCE} |
| -rg | Resource group argument. If no value is passed, then environment variable is null. | $(ENV:RESOURCE-GROUP) |

For more information on these arguments, see [Launching the main automation script](05-launching-the-main-automation-script.md).

## Shared parameters

Several groups of parameters are used in multiple parameters files. 

### General settings

These parameters define VDC settings used by all deployments.

| **Parameter name**               | **Type**                  | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
|----------------------------------|---------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| organization-name                | String                    | Shorthand name of the organization or group deploying the VDC. This is used as a naming prefix when creating resource groups and resources. It should not contain spaces but may contain dashes and underscores.                                                                                                                                                                                                                                                   |
| tenant-id                        | Azure AD Tenant ID (GUID) | ID of the Azure Active Directory tenant associated with the Azure subscription you're deploying resources to.                                                                                                                                                                                                                                                                                                                                                      |
| deployment-user-id               | Azure AD User ID (GUID)   | ID of the user account deploying the shared services Key Vault. This user is set as the default service principal for the environment's vault.                                                                                                                                                                                                                                                                                                                                 |
| vdc-storage-account-name         | String                    | Storage account where deployment output and scripts are stored. All VDC automation storage accounts within a subscription are created within the vdc-storage-rg resource group.                                                                                                                                                                                                                                                                                    |
| vdc-storage-account-rg           | String                    | Resource group containing VDC storage accounts.                                                                                                                                                                                                                                                                                    |
| module-deployment-order          | String[Array]             | This is a list of the resource modules you can provision in a deployment. Each item corresponds to folder names in both the deployments and parameters folder where corresponding Resource Manager templates and parameters files reside. A resource type must be defined in this list to be used by the automation deployment scripts. If attempting to deploy all resources, the deployment scripts attempt to process resources in the order they appear in this list. |
| validation-dependencies          | String[Array]             | This is a list of the resource modules that are deployed as part of deployment validation. Some dependencies, such as a Key Vault may need to exist in a subscription to validate other components of a deployment. Note that if any resources in this list themselves have dependencies defined in a shared services or workload module-dependencies parameter, those dependencies will also be deployed as is done in standard  deployments. See the [deployment validation](11-deployment-validation.md) topic for more information on this parameter is used. |

### Common network parameters

The network parameters object is used by multiple parameters files to define virtual network settings for a deployment. Note that all parameters in this section are required. If a setting is unused, leave it as blank rather than omit the parameter. It's recommended that when creating a new network component, such as a subnet definition, it may be easier to copy an existing definition and modify it than creating a new definition manually to ensure you've correctly included all the required parameters.  

| Parameter name                | Type                | Description                                                                                                                                                                                |
|-------------------------------|---------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| address-prefix                | CIDR range          | A CIDR range definition for the virtual network. This range must not overlap with the on-premises network or any workload network ranges.                                                     |
| application-security-groups   | Object[Array]       | An array of objects representing Application Security Group (ASG) definitions. Each object contains a name parameter for an ASG                                                            |
| network-security-groups       | Object[Array]       | An array of Network Security Group (NSG) definitions, each definition contains two parameters:<ul><li>name [String]: name for the NSG rule.</li><li>rules [Object]: collection of NSG rule definitions.</li></ul> |
| network-security-groups/rules | Object[Array]       | An array of NSG rules definition. Each definition contains the following parameters: <ul><li>name [String] - Name of the rule.</li><li>properties [Object] - The rules property object contains the following parameters:</li><ul><li>access - Allow/Deny</li><li>destinationAddressPrefixes - Array of assigned destination CIDR ranges</li><li>destinationAddressPrefix - Single assigned destination CIDR range</li><li>destinationPortRange - Range of destination port ranges (for example: 22-43)</li><li>destinationPortRanges - Array of individual destination ports</li><li>direction - Inbound/Outbound</li><li>priority - priority relative to other rules</li><li>protocol - TCP/UDR</li><li>sourceAddressPrefix - assigned source CIDR range</li><li>sourcePortRange - Range of source port ranges (for example: 22-43)</li><li>sourcePortRanges - Array of individual source ports</li><li>destinationApplicationSecurityGroups - Array of ASGs that apply to the destination</li><li>sourceApplicationSecurityGroups - Array of ASGs that apply to the source</li></ul></ul>|
| user-defined-routes           | Object[Array]       | An array of User Defined Route (NSG) definitions, each definition contains two parameters: <ul><li>name [String]: name for the UDR collection.</li><li>routes [Object]: collection of UDR definitions.</li></ul> |
| user-defined-routes/routes    | Object[Array]       | An array of UDR definitions. Each definition contains the following parameters: <ul><li>name [String] - Name of the route.</li><li>properties [Object] - The route property object contains the following parameters:</li><ul><li>addressPrefix [CIDR range] - IP addresses that the route applies to.</li><li>nextHopIpAddress [IPV4 address] - IP address to route traffic to.</li><li>nextHopType [String] - One of the [allowed next hop types](https://docs.microsoft.com/azure/network-watcher/network-watcher-next-hop-overview). </li></ul></ul> |
| subnets                       | Object[Array]       | An array of subnet definitions for the virtual network. Each definition contains the following parameters: <ul><li>name [String] - Subnet name<li>address-prefix [CIDR range] - IP address range definition for the subnet.</li><li>network-security-group [String] - Name of NSG to attach to the subnet.</li><li>user-defined-route [String] - Name of UDR collection to attach to the subnet.</li><li>service-endpoints [Array] - List of PaaS service endpoint to attach to the subnet.</li></ul> |
| dns-servers                   | IPV4 Address[Array] | An array of one or more DNS entries that the virtual network will use for name resolution.  |

### Common module dependency parameters

The module-dependencies parameters object is used by multiple parameters files to define the location of deployment module files, the module version being used, and dependencies for that module. Module dependency parameters are required unless otherwise specified.

| Parameter name                | Type                | Description                                                                                                                                                                                |
|-------------------------------|---------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| import-module                 | String              | Optional path value specifying where resource modules folders are located. If specified, the deployment scripts will look for the module files in a subfolder (corresponding to the module name) of this path. Supports absolute file paths or relative paths [using the file() function]. Relative paths should be based off of the root vdc automation folder.<br/>If this value is not specified, the deployment will look for resource module folders under the root vdc automation folder unless paths are specified in the module dependency definition's source object. |
| modules                       | Object[Array]       | The modules array contains a list of module dependency definitions. Each definition contains the following properties describing a deployment module:<ul><li>module [String] - Deployment module name. Should correspond to the name listed in the parameter file's module-deployment-order array and the folder name where the module source files are located.</li><li>same-resource-group [Boolean] - If set to true, this setting forces dependent resources to deploy in the same resource group as the resource (optional).</li><li>create-resource-group [Boolean] - If set to false, this setting deploys the resource in the same resource group as its dependency (optional).</li><li>resource-group-name [String] Allows you to override the default resource group name used in a deployment (optional).</li><li>source [Object] - Information about the source files that make up the module. Contains the following properties:<ul><li>version [String] - version of the module code used for the deployment. Should match the version folder where source files are located.</li><li>template-path [String] - Path specifying location of the ARM deployment file used by the module. Overrides the import-module parameter if used and offers the same pathing options (optional).</li><li>parameters-path [String] - Path specifying location of the ARM parameters file used by the module. Overrides the import-module parameter if used and offers the same pathing options (optional).</li><li>policy-path [String] - Path specifying location of the ARM policy file used by the module. Overrides the import-module parameter if used and offers the same pathing options (optional).</li></li></ul><li>dependencies [Array] - list of modules this module is dependent on.</li></ul> |

## Simulated on-premises deployment parameters

These parameters are used to deploy the simulated on-premises environment (/archetypes/on-premises/archetype.json).

### Shared-services settings (on-premises parameters file)

| **Parameter name** | **Type**               | **Description**                                            |
|--------------------|------------------------|------------------------------------------------------------|
| subscription-id    | Subscription ID (GUID) | ID of the subscription that shared-services resources are deployed to. |
| deployment-name    | String                 | Name of the shared-services deployment.                                |

### Simulated on-premises settings (on-premises parameters file)

| **Parameter name**            | **Type**               | **Description**                                                                                                                                                                                                                                                   |
|-------------------------------|------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| subscription-id               | Subscription ID (GUID) | ID of the subscription that simulated on-premises resources are deployed to.                                                                                                                                                                                      |
| deployment-name               | String                 | Shorthand name of the simulated on-premises deployment. Used as a secondary naming prefix when provisioning resources. This value should not contain spaces but may contain dashes and underscores.                                                               |
| region                        | String                 | The Azure region where simulated on-premises resources are deployed (for example, "West US" or "France South"). [Full list of regions](https://azure.microsoft.com/regions/)                                                                                |
| gateway-type                  | String                 | Specifies the type of connection with the shared-services network—either "vpn" or "expressroute".      |
| gateway-sku                   | String                 | Specifies the Gateway SKU used. Allowable values: <ul><li>Basic</li><li>VpnGw1</li><li>VpnGw2</li><li>VpnGw3</li></ul>[Gateway SKU details](https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#gwsku)                                                            |
| vpn-type                      | String                 | Specifies the [type of VPN gateway](https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-connect-multiple-policybased-rm-ps#about-policy-based-and-route-based-vpn-gateways) used to connect with the shared-services network—either "RouteBased" or "PolicyBased." |
| primaryDC-IP                  | IPV4 address           | IP address of on-premises domain controller.                                                                                                                                                                                                        |
| network                       | [Network object](#common-network-parameters)                 | Configuration parameters for the simulated on-premises virtual network. |
| domain-name                   | String                 | Domain name used by the on-premises network.                                                                                                                                                                                                                                                                                                            |
| cloud-zone                    | String                 | Name of cloud DNS zone to be used for name services addressing the VDC resources                                                                                                                                                                                                                                                                                                            |
| AD-sitename                   | String                 | Site name used to register VDC hosted Active Directory Domain Services (ADDS) servers with the on-premises domain.                                                                                                                                  |
| domain-admin-user             | String                 | Domain user with rights to add trust relationship between on-premises domain and VDC hosted domain controllers.                                                                                                                                    |
| module-dependencies           | [Module Dependencies object](#common-module-dependency-parameters) | This object defines the locations, dependencies,  and behavior of resource modules used for a deployment. |

## Shared-services deployment parameters

These parameters are defined in the shared-services configuration file (/archetypes/shared-services/archetype.json).

### On-premises settings (Shared-services parameters file)

| **Parameter name**      | **Type**                  | **Description**                                                                                                                                                                                                                                     |
|-------------------------|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| subscription-id         | Subscription ID (GUID)    | ID of the subscription that contains your simulated on-premises resources. Only used when test on-premises environments are Azure-based (optional).                                                                                                 |
| location                | String                    | The Azure region where on-premises resources are deployed (for example, "West US" or "France South"). [Full list of regions](https://azure.microsoft.com/regions/). Only needed when using an Azure hosted simulated on-premises environment. |
| vnet-rg                 | String                    | If using an Azure hosted simulated on-premises, this is the name of the resource group containing that environment's virtual network. Only used when test on-premises environments are Azure-based (optional).                                      |
| gateway-name            | String                    | If using an Azure hosted simulated on-premises, this is the name of the virtual gateway for that environment. Only used when test on-premises environments are Azure-based (optional).                                                              |
| address-range           | CIDR range                | CIDR range for the on-premises network.                                                                                                                                                                                                             |
| primaryDC-IP            | IPV4 address              | IP address of on-premises domain controller.                                                                                                                                                                                                        |
| allow-rdp-address-range | IPV4 address/CIDR range   | Allowed IP address or range authorized to connect to the VDC shared-services management VMs from on-premises.                                                                                                                                                   |
| AD-sitename             | String                    | Site name used to register VDC hosted Active Directory Domain Services (ADDS) servers with the on-premises domain.                                                                                                                                  |

### Shared-services settings (Shared services parameters file)

| **Parameter name**                    | **Type**               | **Description**                                                                                                                                                                                                                                                                                                                                          |
|---------------------------------------|------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| subscription-id                       | Subscription ID (GUID) | ID of the subscription that shared-services resources are deployed to.                                                                                                                                                                                                                                                                                               |
| deployment-name                       | String                 | Shorthand name of the shared-services itself. Used as a secondary naming prefix when provisioning resources. This must be unique among your organization's VDC instances. If you use a duplicate name, the deployment will overwrite existing deployments or not complete successfully. This value should not contain spaces but may contain dashes and underscores. |
| region                                | String                 | The Azure region where shared-services resources are deployed (for example, "West US" or "France South"). [Full list of regions](https://azure.microsoft.com/regions/)                                                                                                                                                                                         |
| ancillary-region                      | String                 | Alternate Azure region where the operations and monitoring resources are deployed. This should not be the same as the region where the shared-services is hosted to ensure redundancy. [Full list of regions](https://azure.microsoft.com/regions/)                                                                                                            |
| gateway-type                          | String                 | Specifies the type of connection with the on-premises network—either "vpn" or "expressroute".                                                                                                                                                                                                                                                            |
| gateway-sku                           | String                 | Specifies the Gateway SKU used. Allowable values: <ul><li>Basic</li><li>VpnGw1</li><li>VpnGw2</li><li>VpnGw3</li></ul>[Gateway SKU details](https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#gwsku)                                                            |
| vpn-type                              | String                 | Specifies the [type of VPN gateway](https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-connect-multiple-policybased-rm-ps#about-policy-based-and-route-based-vpn-gateways) used to connect with the on-premises network—either "RouteBased" or "PolicyBased."                                                                                |
| enable-ddos-protection                | String                 | Specifies if [Azure DDoS Protection](https://docs.microsoft.com/azure/virtual-network/ddos-protection-overview) is enabled on the shared-services virtual network automatically on creation.                                                                                                                                                                   |
| azure-firewall-private-ip             | IPV4 address           | IP address assigned to the Azure Firewall controlling VDC access to the Internet.                                                                                                                                                                                             |
| ubuntu-nva-lb-ip-address              | IPV4 address           | IP address assigned to the Linux VM-based Firewall controlling VDC access to the Internet. (Optional. Used when deploying Ubuntu VM for firewall purposes.) |
| ubuntu-nva-address-start              | IPV4 address           | IP address assigned to the Linux VM-based Firewall controlling VDC access to the Internet. (Optional. Used when deploying Ubuntu VM for firewall purposes.) |
| squid-nva-address-start               | IPV4 address           | IP address assigned to the Squid proxy NVA. (Optional. Used when deploying a Squid NVA for proxy services.)                                                                                                                                                                                            |
| domain-admin-user                     | String                 | Domain user with rights to add trust relationship between on-premises domain and VDC hosted domain controllers. <br/><br/>Note that to prevent conflicts when Key Vault stores this user information as a secret, domain-admin-user must be different than local-admin-user. |
| domain-name                           | String                 | Domain name used by your on-premises network.                                                                                                                                                                                                                                                                                                            |
| local-admin-user                      | String                 | User account to create as local admin on VMs created within the shared-services. <br/><br/>Note that to prevent conflicts when Key Vault stores this user information as a secret, domain-admin-user must be different than local-admin-user.  |
| adds-address-start                    | IPV4 address           | IP address for the first ADDS server deployed to the shared-services subnet. Additional servers use an IP address incremented from this starting address.                                                                                                                                                                                                |
| enable-encryption                     | Boolean                | Determines if virtual disks are automatically encrypted on creation. Windows VM encryption is only supported. When this value is set to true, the VDC deployment automation engine will use the values from encryption-keys-for to create certificates in Key Vault.                                                                                                                                                                                                |
| network                               | [Network object](#common-network-parameters)                 | Configuration parameters for the shared-services virtual network. <br/><br/> Note that for the Hub deployment, the subnet entries for the  *AzureFirewallSubnet* and *GatewaySubnet* subnets are required and should not be modified from the versions in the sample parameters file. |
| encryption-keys-for                   | String[Array]          | Lists the module names that need encryption keys generated in Key Vault. If modules are specified, the VDC deployment automation engine will create certificates in Key Vault. These certificates are passed to a VM deployment to provide Bitlocker encryption (Windows encryption VMs are only supported). This parameter is used by the deployment automation engine only when enable-encryption property is set to true.                                                                                                                                                                                                     |
| module-dependencies           | [Module Dependencies object](#common-module-dependency-parameters) | This object defines the locations, dependencies,  and behavior of resource modules used for a deployment. |

## Shared workload deployment parameters

These parameters are used in all workload deployment parameters file. See sample [PaaS workload deployment for an example](../archetypes/paas/archetype.test.json).

### On-premises settings (Workload parameters file)

| **Parameter name**      | **Type**                  | **Description**                                                                                                                                                                                                                                     |
|-------------------------|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| address-range           | CIDR range                | CIDR range for the on-premises network.                                                                                                                                                                                                             |
| primaryDC-IP            | IPV4 address              | IP address of on-premises domain controller.                                                                                                                                                                                                        |
| allow-rdp-address-range | IPV4 address/CIDR range   | Allowed IP address or range authorized to connect to the VDC shared-services management VMs from on-premises.                                                                                                                                                                                                        |

### Shared-services settings (Workload parameters file)

| **Parameter name**                | **Type**               | **Description**                                                |
|-----------------------------------|------------------------|----------------------------------------------------------------|
| subscription-id                   | Subscription ID (GUID) | ID of the subscription that share resources are deployed to.     |
| vnet-rg                           | String                 | Name of the resource group containing the shared-services virtual network. |
| vnet-name                         | String                 | Name of the shared-services virtual network.                               |
| app-gateway-subnet-name           | String                 | Name of the shared-services network subnet hosting the application gateway.|
| app-gateway-name                  | String                 | Name of the shared-services network's application gateway.                 |
| gw-udr-name                       | String                 | Name of the shared-services network's gateway User Defined Route (UDR).    |
| kv-rg                             | String                 | Name of the resource group containing the shared-services Key Vault.       |
| kv-name                           | String                 | Name of the shared-services Key Vault.                                     |
| azure-firewall-private-ip-address | IPV4 address           | IP address assigned to the shared-services Azure Firewall.                 |
| azure-firewall-name             | IPV4 address           | Name of the Azure Firewall controlling VDC access to the Internet.                                                                                                |
| ubuntu-nva-lb-ip-address              | IPV4 address           | IP address assigned to the Linux VM-based Firewall controlling VDC access to the Internet. (Optional. Used when deploying Ubuntu VM for firewall purposes.) |
| ubuntu-nva-address-start              | IPV4 address           | IP address assigned to the Linux VM-based Firewall controlling VDC access to the Internet. (Optional. Used when deploying Ubuntu VM for firewall purposes.) |
| squid-nva-address-start               | IPV4 address           | IP address assigned to the Squid proxy NVA. (Optional. Used when deploying a Squid NVA for proxy services.)                                                 |
| deployment-name                   | String                 | Name of the shared-services deployment.                                    |
| adds-address-start                    | IPV4 address           | IP address for the first ADDS server deployed to the shared-services shared-services subnet. Additional servers use an IP address incremented from this starting address. |
| domain-name                           | String                 | Domain name used by your on-premises network.                                                                                                                                                                                                                                                                                                            |
| domain-admin-user                     | String                 | Domain user with rights to add trust relationship between on-premises domain and VDC hosted domain controllers. <br/><br/>Note that to prevent conflicts when Key Vault stores this user information as a secret, domain-admin-user must be different than local-admin-user. |

### Workload settings (Workload parameters file)

| **Parameter name**            | **Type**               | **Description**                                                                                                                                                                                                                                                                                                                                     |
|-------------------------------|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| subscription-id               | Subscription ID (GUID) | ID of the subscription that workload resources are deployed to.                                                                                                                                                                                                                                                                                        |
| deployment-name               | String                 | Shorthand name of the workload. Used as a secondary naming prefix when provisioning resources. This must be unique among your organization's VDC instances. If you use a duplicate name, the deployment will overwrite existing deployments or not complete successfully. This value should not contain spaces but may contain dashes and underscores. |
| domain-name                   | String                 | Domain name used by your on-premises network.                                                                                                                                                                                                                                                                                                       |
| region                        | String                 | The Azure region where workload resources are deployed (for example, "West US" or "France South"). [Full list of regions](https://azure.microsoft.com/regions/)                                                                                                                                                                                  |
| ancillary-region              | String                 | Alternate Azure region where the operations and monitoring resources are deployed. This should not be the same as the region where the workload is hosted to ensure redundancy. [Full list of regions](https://azure.microsoft.com/regions/)                                                                                                     |
| log-analytics-region          | String                 | Azure region where log analytics instance is hosted. |
| enable-encryption                     | Boolean                | Determines if virtual disks are automatically encrypted on creation. Windows VM encryption is only supported. When this value is set to true, the VDC deployment automation engine will use the values from encryption-keys-for to create certificates in Key Vault.                                                                                                                                                                                                      |
| enable-ddos-protection                | String                 | Specifies if [Azure DDoS Protection](https://docs.microsoft.com/azure/virtual-network/ddos-protection-overview) is enabled on the workload virtual network automatically on creation. |
| local-admin-user                      | String                 | User account to create as local admin on VMs created within the workload. <br/><br/>Note that to prevent conflicts when Key Vault stores this user information as a secret, domain-admin-user must be different than local-admin-user.  |
| vnet-address-prefix           | CIDR range             | A CIDR range definition for the workload virtual network. This range must not overlap with the on-premises network, the shared-services network, or any other workload network ranges.                                                                                                                                                                                |
| network                               | [Network object](#common-network-parameters)                 | Configuration parameters for the shared-services virtual network. |
| encryption-keys-for           | String[Array]          | Lists the module names that need encryption keys generated in Key Vault. If modules are specified, the VDC deployment automation engine will create certificates in Key Vault. These certificates are passed to a VM deployment to provide Bitlocker encryption (Windows encryption VMs are only supported). This parameter is used by the deployment automation engine only when enable-encryption property is set to true.                                                                                                                                                                                                |
| module-dependencies           | [Module Dependencies object](#common-module-dependency-parameters) | This object defines the locations, dependencies,  and behavior of resource modules used for a deployment. |

## Workload-specific parameters

Some workload examples use specific parameters that are not common to all workloads.

### iaas deployment parameters (workload section)

These parameters are specific to the [iaas example](../archetypes/iaas/parameters/archetype.test.json) workload deployment.

| **Parameter name**            | **Type**               | **Description**                                                                                                                                                                                                                                                                                                                                     |
|-------------------------------|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| vmapp-start-ip-address        | IPV4 Address     | IP address of first virtual machine instance. Additional instances will increment off this value.     |
| vmapp-lb-ip-address        | IPV4 Address        | IP address of the virtual machine load balancer.                        |
| vmapp-prefix": "web-app       | String           | Prefix to apply to virtual machine names    |
| sql-server-cluster-name    | String     | Name of SQL Server failover cluster.    |
| sql-server-start-ip-address        | IPV4 Address | IP address of first SQL Server instance. Additional instances will increment off this value.     |
| sql-server-ilb-ip-address        | IPV4 Address   | IP address of the SQL Server load balancer.                        |
| sql-server-cluster-ip-address        | IPV4 Address  | IP address for used by clients to connect to the SQL Server failover cluster.     |

### sap-hana deployment parameters (workload section)

These parameters are specific to the [sap-hana](../archetypes/sap-hana/archetype.test.json) workload deployment.

| **Parameter name**            | **Type**               | **Description**                                                                                                                                                                                                                                                                                                                                     |
|-------------------------------|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| iscsi-ip                      | IPV4 Address           | IP address of the iSCSI virtual storage array    |  
| iscsi-os-type                 | String                 | iSCSI virtual storage array operating system type. Allowed values: <ul><li>Windows Server 2016 Datacenter</li><li>SLES 12 SP3</li><li>SLES 12 SP3 BYOS</li><li>SLES 12 SP2</li><li>SLES 12 SP2 BYOS</li></ul>   |
| iscsi-iqn1                    | String                 | iSCSI qualified name (IQN) of first iSCSI instance.     |
| iscsi-iqn1-client1            | String                 | iSCSI qualified name (IQN) of first iSCSI instance's client1.     |
| iscsi-iqn1-client2            | String                 | iSCSI qualified name (IQN) of first iSCSI instance's client2.     |
| iscsi-iqn2                    | String                 | iSCSI qualified name (IQN) of second iSCSI instance.     |
| iscsi-iqn2-client1            | String                 | iSCSI qualified name (IQN) of second iSCSI instance's client1.     |
| iscsi-iqn2-client2            | String                 | iSCSI qualified name (IQN) of second iSCSI instance's client1.     |
| iscsi-iqn3                    | String                 | iSCSI qualified name (IQN) of third iSCSI instance.     |
| iscsi-iqn3-client1            | String                 | iSCSI qualified name (IQN) of third  iSCSI instance's client1.     |
| iscsi-iqn3-client2            | String                 | iSCSI qualified name (IQN) of third iSCSI instance's client2.     |
| nfs-lb-ip                     | IPV4 Address           | IP address of NFS load balancer.     |
| nfs-address-start             | IPV4 Address           | IP address of first NFS server instance (additional instance will iterate from this address).    |
| hana-sid                      | String                 | SAP system ID for the deployment.     |
| subscription-email            | String                 | Email address associated with your SAP account.   |
| hana-os-type                  | String                 | Hana server OS type.            |
| hana-lb-ip                    | IPV4 Address           | Hana load balancer IP address.    |
| hana-address-start            | IPV4 Address           | IP address of first Hana server instance (additional instance will iterate from this address).    |
| ascs-os-type                  | String                 | SAP Central Services (ASCS/SCS) OS type.    |
| nw-address-start              | IPV4 Address           | IP address of first NetWeaver server instance (additional instance will iterate from this address).    |
| nw-os-type                    | String                 | NetWeaver server OS type.    |

# Add PCF Here

Add parameters table.
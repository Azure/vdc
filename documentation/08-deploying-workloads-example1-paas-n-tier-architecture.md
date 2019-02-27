# Workload example 1: PaaS N-tier architecture

The toolkit's first example workload deployment creates the resources to host an
N-tier application using managed platform services. This provisions an
Azure SQL Database securely connected to the workload virtual network using a
[Virtual Network service
endpoint](https://docs.microsoft.com/azure/virtual-network/virtual-network-service-endpoints-overview)
for the data tier. The web and business tiers are provisioned using an [Azure
App Service
Environment](https://docs.microsoft.com/azure/app-service/environment/intro)
securely connected to the workload virtual network.

## Prerequisite: create and configure your parameters file

As discussed in the [parameter files](03-parameters-files.md#parameters-files) topic, the VDC Automation Toolkit provides a default test version of the top-level deployment parameter file. You will need to create a new version of this file before running your deployment. 

To do this, navigate to the toolkit's [archetypes/paas](../archetypes/paas) folder, then make a copy of the *archetype.test.json*, and name this copy *archetype.json*. Then proceed to edit archetype.json providing the subscription, organization, networking, and other configuration information that you want to use for your deployment. Make sure you use values for the shared services and on-premises parameters consistent with those components of your VDC deployment.

If your copy of the toolkit is associated with a git repository, the [.gitignore](../.gitignore) file provided by the default VDC Automation Toolkit is set to prevent this archetype.json file from being pushed to your code repository.

## Deploy workload infrastructure

All workload environments require a common set of operations, key vault, and virtual network resources before they can connect to the shared services network and host workloads. The following steps will  deploy these required resources. 

![](media/VDC1.5_Spoke1_Blank.png)

### Step 1: Deploy workload operations and monitoring resources

**Required role: SysOps**

This step provisions the operations and monitoring resources for the workload environment.

Start the "la" deployment by running the following command in the terminal or
command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/paas/archetype.json" -m "la"*

[Windows]

>   *py vdc.py create workload -path "archetypes/paas/archetype.json" -m "la"*

[Docker]

>   *python vdc.py create workload -path "archetypes/paas/archetype.json" -m "la"*

This deployment creates the *{organization name}-{deployment name}-la-rg*
resource group that hosts the resources in the following table.

| **Resource**                             | **Type**      | **Description**                              |
|------------------------------------------|---------------|----------------------------------------------|
| {organization name}-{deployment name}-oms | Log Analytics | Log Analytics instance for monitoring the shared services network. |

### Step 2: Deploy workload Key Vault

**Required role: SecOps**

This step deploys the workload "kv" resource, which deploys a Key Vault for the
workload environment and generates the encryption keys that are used for resources
deployed by the workspace DevOps teams.

Start the "kv" deployment by running the following command in the terminal or
command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/paas/archetype.json" -m "workload-kv"*

[Windows]

>   *py vdc.py create workload -path "archetypes/paas/archetype.json"
>   -m "workload-kv"*

[Docker]

>   *python vdc.py create workload -path "archetypes/paas/archetype.json"
>   -m "workload-kv"*

This deployment creates the *{organization name}-{deployment name}-kv-rg*
resource group that hosts the resources listed in the following table.

| **Resource**                                           | **Type**        | **Description**                                                        |
|--------------------------------------------------------|-----------------|------------------------------------------------------------------------|
| {organization name}-{deployment name}-kv               | Key Vault       | Key Vault instance for the workload. One certificate deployed by default. |
| {organization name}{deployment name (dashes removed)}{random characters} | Storage account | Location of Key Vault audit logs.                                      |

### Step 3: Deploy workload virtual network

**Required role: NetOps**

This step involves two resource deployments in the following order:

-   The "nsg" deployment module creates  the network security groups (NSGs) and
    Azure security groups (ASGs) that secure the workload virtual network. By
    default, the example workload net deployment creates a set of NSGs and ASGs
    compatible with an *n*-tier application, consisting of web, business, and
    data tiers.

-   The "net" deployment module creates  the workload virtual network, along with
    setting up the default subnet and User Defined Routes (UDRs) used to route
    traffic to the shared services network. This deployment also creates the VNet peering
    that connects the shared services and workload networks.

Start the "nsg" deployment by running the following command in the terminal or
command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/paas/archetype.json" -m "nsg"*

[Windows]

>   *py vdc.py create workload -path "archetypes/paas/archetype.json" -m "nsg"*

[Docker]

>   *python vdc.py create workload -path "archetypes/paas/archetype.json" -m "nsg"*

Then start the "net" deployment by running the following command in the terminal
or command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/paas/archetype.json" -m "workload-net"*

[Windows]

>   *py vdc.py create workload -path "archetypes/paas/archetype.json" -m "workload-net"*

[Docker]

>   *python vdc.py create workload -path "archetypes/paas/archetype.json" -m "workloadnet"*

These deployments create the *{organization name}-{deployment name}-net-rg*
resource group that hosts the resources detailed in the following table.

| **Resource**                                                 | **Type**               | **Description**                                                      |
|--------------------------------------------------------------|------------------------|----------------------------------------------------------------------|
| {organization name}-{deployment name}-vnet                    | Virtual network        | The primary workload virtual network, with a single default subnet.     |
| {organization name}-{deployment name}-{default subnet name}-nsg | Network security group | Network security group attached to the default subnet.               |
| {organization name}-{deployment name}-{default subnet name}-udr                     | Route table            | User Defined Routes for routing traffic to and from the shared services network. |
| {deployment name (dashes removed)}                 | Storage account              | Storage location for virtual network diagnostic data.                                |

## Deploy workload resources 

Once the workload operations, Key Vault, and virtual network resources are provisioned, your team can begin deploying actual workload resources. Performing the following tasks provisions the Azure SQL Database and App Service Environment needed for DevOps to deploy an application with a data, business, and web tier.

![](media/VDC1.5_Spoke1-complete.png)

### Deploy Azure SQL Database

The "sqldb" deployment module creates the Azure SQL Database and secure
service endpoint used for the application's data tier. Start this deployment by
running the following command in the terminal or command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/paas/archetype.json" -m "*sqldb*"*

[Windows]

>   *py vdc.py create workload -path "archetypes/paas/archetype.json" -m "*sqldb*"*

[Docker]

>   *python vdc.py create workload -path "archetypes/paas/archetype.json" -m "*sqldb*"*

This deployment creates the *{organization name}-{deployment name}-sqldb-rg*
resource group that hosts the resources shown in the following table.

| **Resource**                                      | **Type**     | **Description**                                           |
|---------------------------------------------------|--------------|-----------------------------------------------------------|
| {organization name}-{deployment name}-db-server01 | SQL server   | Azure SQL Database server hosting the data-tier database. |
| sqldb01                                           | SQL database | Azure SQL Database.                                       |

### Deploy App Service Environment for business and web tiers

The "ase" deployment module creates a new App Service Environment within the
workload virtual network and creates three instances of a single app service that
provides the application's web tier. Start this deployment by running the
following command in the terminal or command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/paas/archetype.json" -m "*ase*"*

[Windows]

>   *py vdc.py create workload -path "archetypes/paas/archetype.json" -m "*ase*"*

[Docker]

>   *python vdc.py create workload -path "archetypes/paas/archetype.json" -m "*ase*"*

This deployment creates the *{organization name}-{deployment name}-ase-rg*
resource group that hosts the following resources:

| **Resource**                                   | **Type**                | **Description**                                                             |
|------------------------------------------------|-------------------------|-----------------------------------------------------------------------------|
| samplemvc                                      | App Service             | Example App service instance deployed to the App Service plan.              |
| {organization name}-{deployment name}-app-plan | App Service plan        | Default App Server plan for hosting DevOps App Services.                    |
| {organization name}-{deployment name}-ase      | App Service Environment | App Service Environment deployed securely inside the workload virtual network. |

Once the App Service Environment is created, DevOps teams can create [additional
web and business tier app
services](https://docs.microsoft.com/azure/app-service/environment/create-ilb-ase#create-an-app-in-an-ilb-ase).

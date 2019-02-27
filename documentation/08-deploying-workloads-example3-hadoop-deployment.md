# Workload example 3: Hadoop deployment

The toolkit's third example workload workload is a
[Cloudbreak](https://azure.microsoft.com/blog/hortonworks-extends-iaas-offering-on-azure-with-cloudbreak/)
managed Hadoop deployment, which takes advantage of Azure's managed [Database
for PostgreSQL](https://azure.microsoft.com/services/postgresql/) and
[Database for MySQL](https://azure.microsoft.com/services/mysql/)
offerings.

## Prerequisite: create and configure your parameters file

As discussed in the [parameter files](03-parameters-files.md#parameters-files) topic, the VDC Automation Toolkit provides a default test version of the top-level deployment parameter file. You will need to create a new version of this file before running your deployment. 

To do this, navigate to the toolkit's [archetypes/cloudbreak](../archetypes/cloudbreak) folder, then make a copy of the *archetype.test.json*, and name this copy *archetype.json*. Then proceed to edit archetype.json providing the subscription, organization, networking, and other configuration information that you want to use for your deployment. Make sure you use values for the hub and on-premises parameters consistent with those components of your VDC deployment.

If your copy of the toolkit is associated with a git repository, the [.gitignore](../.gitignore) file provided by the default VDC Automation Toolkit is set to prevent this azureDeploy.parameters.json file from being pushed to your code repository.

## Deploy workload infrastructure

All workload environments require a common set of operations, key vault, and virtual network resources before they can connect to the hub network and host workloads. The following steps will  deploy these required resources. 

### Step 1: Deploy workload operations and monitoring resources

**Required role: SysOps**

This step provisions the operations and monitoring resources for the workload
environment.

Start the "ops" deployment by running the following command in the terminal or
command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "la"*

[Windows]

>   *py vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "la"*

[Docker]

>   *python vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "la"*

This deployment creates the *{organization name}-{deployment name}-la-rg*
resource group that hosts the resources in the following table.

| **Resource**                             | **Type**      | **Description**                              |
|------------------------------------------|---------------|----------------------------------------------|
| {organization name}-{deployment name}-oms | Log Analytics | Log Analytics instance for monitoring the hub network. |

### Step 2: Deploy workload Key Vault

**Required role: SecOps**

This step deploys the workload "kv" resource, which deploys a Key Vault for the
workload environment and generates the encryption keys that are used for resources
deployed by the workspace DevOps teams.

In addition to the workload Key Vault, this deployment generates a password for the local-admin-user name defined in the workload parameters file. This password is stored as a secret in the vault. To modify the default values for these passwords edit the [Key Vault deployment parameters file](../modules/workload-kv/1.0/azureDeploy.parameters.json) and update the secrets-object parameter.

Start the "kv" deployment by running the following command in the terminal or
command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "workload-kv"*

[Windows]

>   *py vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "workload-kv"*

[Docker]

>   *python vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "workload-kv"*

This deployment creates the *{organization name}-{deployment name}-kv-rg*
resource group that hosts the resources listed in the following table.

| **Resource**                                           | **Type**        | **Description**                                                        |
|--------------------------------------------------------|-----------------|------------------------------------------------------------------------|
| {organization name}-{deployment name}-kv               | Key Vault       | Key Vault instance for the workload. One certificate deployed by default. |
| {organization name}{deployment name (dashes removed)}kvdiag{random characters} | Storage account | Location of Key Vault audit logs.                                      |

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
    traffic to the hub network. This deployment also creates the VNet peering
    that connects the hub and workload networks.

Start the "nsg" deployment by running the following command in the terminal or
command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "nsg"*

[Windows]

>   *py vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "nsg"*

[Docker]

>   *python vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "nsg"*

Then start the "net" deployment by running the following command in the terminal
or command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "workload-net"*

[Windows]

>   *py vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "workload-net"*

[Docker]

>   *python vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "workload-net"*

These deployments create the *{organization name}-{deployment name}-net-rg*
resource group that hosts the resources detailed in the following table.

| **Resource**                                                 | **Type**               | **Description**                                                      |
|--------------------------------------------------------------|------------------------|----------------------------------------------------------------------|
| {organization name}-{deployment name}-vnet                    | Virtual network        | The primary workload virtual network, with a single default subnet.     |
| {organization name}-{deployment name}-{defaultsubnetname}-nsg | Network security group | Network security group attached to the default subnet.               |
| {organization name}-{deployment name}-udr                     | Route table            | User Defined Routes for routing traffic to and from the hub network. |
| business-asg                                                  | Azure security group   | ASG for business-tier assets.                                        |
| web-asg                                                       | Azure security group   | ASG for web-tier assets.                                             |
| data-asg                                                      | Azure security group   | ASG for data-tier assets.                                            |
| {deployment name (dashes removed)}diag{random characters}     | Storage account        | Storage location for virtual network diagnostic data.                                      |

## Deploy workload resources 

Once the workload operations, Key Vault, and virtual network resources are provisioned, your team can begin deploying actual workload resources. Performing the following tasks provisions the availability sets, virtual machines, Azure PostgreSQL, and Azure MySQL resources needed to deploy a virtual machine running a Cloudbreak managed Hadoop application.

A local user account will be created for these machines. The user name is defined in the local-admin-user parameter of the main deployment parameters file. The password for this user is generated and stored in the workload key vault as part of the "kv" deployment.

### Deploy Hadoop Cloudbreak resources

Start the "cb" deployment by running the following command in the terminal or
command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "cb"*

[Windows]

>   *py vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "cb"*

[Docker]

>   *python vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "cb"*

This deployment creates the *{organization name}-{deployment
name}-cb-rg* resource group that hosts the resources listed in
the following table.

| **Resource**                                                  | **Type**                             | **Description**                               |
|---------------------------------------------------------------|--------------------------------------|-----------------------------------------------|
| cb-as                                                         | Availability set                     | Availability set for Hadoop virtual machines. |
| {organization name}{deployment name}cb{random characters}     | Storage account                      | Storage account for Hadoop Cloudbreak VM.            |
| {organization name}{deployment name}cbdiag{random characters} | Storage account                      | Virtual machine diagnostic storage account.   |
| {organization name}-{deployment name}-mysql01                 | Azure Database for MySQL server      | MySQL server for Hadoop.                      |
| {organization name}-{deployment name}-postgresql01            | Azure Database for PostgreSQL server | PostgreSQL server for Hadoop.                 |
| {organization name}-{deployment name}-hdp-cb-vm1              | Virtual machine                      | Hadoop Cloudbreak VM.                                |
| {organization name}-{deployment name}-hdp-cb-vm1-nic1         | Network interface                    | Network interface for VM.                 |

### Deploy Kerberos Domain Controller (KDC)

To enable Kerberos authentication for your Hadoop application, you will need a server in the workload virtual network capable of handling authentication claims. This resource deployment will create a two VMs and an availability set to support a primary and secondary Kerberos Domain Controller that your Hadoop app can use for authentication.

Start the "kdc" deployment by running the following command in the terminal or
command-line interface:

[Linux/OSX]

>   *python3 vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "kdc"*

[Windows]

>   *py vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "kdc"*

[Docker]

>   *python vdc.py create workload -path "archetypes/cloudbreak/archetype.json" -m "kdc"*

This deployment creates the *{organization name}-{deployment
name}-kdc-rg* resource group that hosts the resources listed in
the following table.


| **Resource**                                                                | **Type**          | **Description**                                                            |
|-----------------------------------------------------------------------------|-------------------|----------------------------------------------------------------------------|
| {organization name}-{deployment name}-kdc-as                                | Availability set  | Availability set for KDC servers.                                         |
| {organization name}{deployment name (spaces removed)}kdcdiag{random characters}              | Storage account   | Storage account used to store diagnostic logs related to the KDC servers. |
| {organization name}-{deployment name}-kdc-vm1                               | Virtual machine   | Primary KDC server.                                                       |
| {organization name}-{deployment name}-kdc-vm1-nic                           | Network interface | Virtual network interface for primary KDC server.                         |
| {organization name}{deployment name (spaces removed)}kdcvm1osdsk{random characters} | Disk              | Virtual OS disk for primary KDC server.                                   |
| {organization name}-{deployment name}-kdc-vm2                               | Virtual machine   | Secondary KDC server.                                                     |
| {organization name}-{deployment name}-kdc-vm2-nic                           | Network interface | Virtual network interface for secondary KDC server.                       |
| {organization name}{deployment name (spaces removed)}kdcvm2osdsk{random characters} | Disk              | Virtual OS disk for secondary KDC server.                                 |

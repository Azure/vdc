# Launching the main automation script

To run the deployment script, you need to open a terminal/command line and
navigate to the root of the VDC Toolkit folder, or you can run the
preconfigured Docker image that starts at the correct script folder location.

Before beginning, you need to sign into the Azure CLI tool using the following
command:

>   *az login*

This prompts you to log in using the Azure web interface. 

If your account is
associated with more than one subscription, you'll then need to set the default
subscription you're deploying resources to after you login:

>   *az account set --subscription [subscription\_ID GUID]*

Once this is complete, you can launch a deployment from the
terminal/command-line interface by launching the
[vdc.py](../vdc.py)
script:

*[Linux/OSX]*

>   *python3 vdc.py create {environment type} {arguments}*

*[Windows]:*

>   *py vdc.py create {environment type} {arguments}*

*[Docker]*

>   *python vdc.py create {environment type} {arguments}*


## Environment types

The enviroment type is either "shared-services", "workload,", or "on-premises" indicating which
type of VDC component you are building out.

## Arguments

There are several required and optional arguments that you can pass for a
deployment:

| **Argument**                          | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|---------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| \-path, <br>--configuration-file-path <br>[Required]  | Path pointing to the root parameters file for the shared services, workload, or simulated on-premises deployment you want to initiate.             | \-m, <br>--module <br>[Optional]            | Specifies which resource module to deploy. This value is limited to the list of resource types defined in the top-level shared services or workload parameters file's "resource-deployment-order" array. If this argument is not specified, the script processes each of the resources in the order they appear in the array. <br><br>Creating all resources requires the user running the script to have permissions to deploy all resource types. For shared services and workload deployments, omitting this parameter is only recommended for testing and development purposes, as a production VDC should make use of properly defined roles and separation of responsibility when deploying.<br><br>This argument should not be used when deploying a simulated on-premises environment. |
| \-rg, --resource-group [Optional]     | Resource Group name (String). If specified, resources are created within this group. If the group does not exist, the script creates it. If this parameter is not specified, the script creates a resource group named using a combination of the organization name you set in your main parameters file and the resource type being deployed.      |
| \-l, <br>--location <br>[Optional]            | Location (Azure Region name). Region used when deploying resources. If the region value in your main parameters file is blank, this parameter is required.       |
| \--deploy-dependencies <br>[Optional] | Deploy resource module dependencies. If present, the script deploys any resource modules that are listed as dependencies for the resource you're currently deploying (defined in the top-level deployment parameters file's module-dependencies object). <br><br>If the user running this command does not have the correct permissions to run all of the dependent modules, setting this argument can generate errors. In addition, if the dependent resource modules have already been run for this deployment, the script redeploys these resources using the latest parameter values. |
| \--upload-scripts <br>[Optional]          | Specifies if the scripts folder gets uploaded to the default storage account. Resource deployments will only upload the common toolkit scripts to Azure storage if this argument is included. It's important to use this when deploying any resources that depend on scripts to finish their configuration, like ADDS servers and NVAs. Note this will overwrite any existing scripts previously uploaded.                                                                        |
| \--prevent-vdc-storage-creation <br>[Optional]      | By default, deployments will create a new storage account for output and scripts if one does not exist. Including this argument will prevent this, and only deploy if the target storage account exists. Storage account name is set in the top-level parameter files vdc-*storage-account-name* parameter.      |

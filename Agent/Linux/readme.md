# Azure DevOps - Ubuntu 18.04 Agent

The following sections provide a step-by-step guide to creating an Azure DevOps Agent Image using Packer, spin up an Agent using the Image and add it to the Azure DevOps Agent Pool.

## Prepare your Azure DevOps Account

1. Create an [Azure DevOps Agent pool](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops#creating-agent-pools)

2. Generate a [Personal Access Token (PAT)](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops#create-personal-access-tokens-to-authenticate-access) for your Azure DevOps Organization. When generating the Personal Access Token (PAT), assign the following scopes:

* Agent Pools - Read & Manage
* Deployment Groups - Read & Manage

3. Create a [Service Principal](https://docs.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps?view=azps-2.4.0).

4. Add [RBAC Assignment](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal#add-a-role-assignment) to the service principal created in previous step by adding the service principal as Owner of the subscription that will host the image and agent VMs.

## Build a Packer Image

1. Build a Docker image.

```
docker build --rm -f "dockerfile" -t vdc:latest .
```

> Note: Do not miss the `.` at the end when running the above command.

2. Create a container from the Docker image built in the previous step. Mount the `Agent` folder as a volume in your Docker container when creating the container.

```
docker run -it -v <path-to-vdc-folder>/Agent:/usr/src/app/Agent vdc:latest
```

2. Update the build.sh file under `Agent\Linux` folder with the service principal's client id, client secret, subscription id and tenant id. 

> Note: When saving the build.sh file, save the file in 'LF' mode. If your Operating System is Windows Visutal Studio Code defaults to CRLF. In Visual Studio Code, the option to change from CRLF to LF is available at the bottom left blue bar.

3. Run the command below from PowerShell terminal to build a VM Image

```
cd /usr/src/app/Agent/Linux
bash -c "./build.sh"
```

> VM Image will contain all the required tools, SDKs and CLIs to run the VDC toolkit.

## Create a VM from Packer Image

1. Run the command below from PowerShell terminal to create a VM from the Image

```
bash -c "./vsts-agent-create.sh <organization-url> <personal-access-token> <vsts-pool-name> <agent-vm-name>"
```

> VM will be created in the same resource group, subscription and tenant as the Image created by Packer. The name of this resource group can be found in the build.sh and vsts-agent-create.sh bash scripts.
> VM will have following attributes:
> * Created from the Image built by Packer
> * No Public IP
> * Explicit NSG rule to block all SSH connections
> * Virtual Network with a default subnet
> Note: If you need to allow SSH connectivity from your computer, enable a SSH Connection with a specific IP.

## Ubuntu Agent - Notes

* PowerShell Modules - Az, Pester and Resource Graph are installed and available part of the Agent Image. These modules are installed using `Save-Module` Cmdlet. Ubuntu 18.04 has a specific location for these Modules to be saved. You will find the location of the Module to be saved in the `ubuntu-1804.json` packer file. 

* Installing modules using `Install-Module` will not allow the Cmdlets to be available for use by all users.

# Azure DevOps - Ubuntu 18.04 Agent

The following sections provide a step-by-step guide to creating a Azure DevOps Agent Image using Packer, spin up an Agent using the Image and add it to the Azure DevOps Agent Pool.

## Prepare your Azure DevOps Account

1. Create an Azure DevOps Agent pool.

2. Generate a Personal Access Token (PAT) for your Azure DevOps Organization.

3. Create a service principle and add it to your subscription as Owner. This is the subscription that will be used to host the image and Agent VM.

## Build a Packer Image

1. Build a Docker image and a container from the Docker image by mounting "Agent" folder as a volume in your Docker container.

3. Switch to bash and login using Az Cli Cmd - az login.

4. Update the run.sh file with the service principle and subscription information.

5. Run the bash script to build an VM Image

```
./run.sh
```

## Create a VM from Packer Image

1. Run the bash script to create an instance from the VM Image

```
./vsts-agent-create.sh <organization-url> <personal-access-token> <vsts-pool-name>
```
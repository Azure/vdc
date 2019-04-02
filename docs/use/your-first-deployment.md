# Your first deployment

For your first use of the Azure Virtual Datacenter Automation Toolkit we will deploy the  [_simulated on-premises archetype_](../archetypes/on-premises/overview.adoc). This tutorial is intended to get you up and running quickly with the toolkit. See additional documentation for more details on using the toolkit.

This tutorial assumes that you have already [set up the toolkit](readme.md) to run in Docker or locally. For local setups, it assumes that the Azure CLI is also installed.

We will go through the following steps:

1. Logging into Azure with the CLI
1. Collecting subscription, tenant, and user information.
1. Creating an archetype configuration
1. Deploying the archetype

> If you are using Docker, as recommended, be sure to [run the image](../setup/setup-docker.md) before proceeding.

## Logging in

First, login with the Azure CLI:

`az login`

This prompts you to log in using the Azure web interface.

If your account is associated with more than one subscription, you'll then need to set the default subscription you're deploying resources to after you login:

`az account set --subscription [subscription id]`

## Gathering required information

Before we can deploy, we will need to provide the toolkit with:

- ID for the targeted Azure Active Directory (AAD) tenant
- ID for the targeted subscription
- Object ID for your AAD user (to provide access to the deployed Key Vault)

These values can be acquired from the CLI.

Run `az account show`

- The value for`"id"` is the subscription ID
- The value for `"tenantId"` is the AAD tenant ID

The following command retrieves your AAD user's Object ID, this command must be executed in your local computer (using az cli version 2.0.55 or greater) or in [Azure Cloud Shell](https://docs.microsoft.com/azure/cloud-shell/overview). 

**NOTE:**
> Running `az ad signed-in-user` command inside the Docker container will result in an error.

Run `az ad signed-in-user show --query "objectId"`

- This command returns the value for `"object-id"`

## Editing the archetype archetype.json

We need to create an instance of the configuration for the on-premises archetype using value unique to our deployment.

1. Locate the sample configuration at [`archetypes/on-premises/archetype.test.json`](../archetypes/on-premises/archetype.test.json).
1. Copy the sample configuration and name it `archetype.json`. It should be place in `archetypes/on-premises/`.
    - The file name: `archetype.json` is included in .gitignore, the reason is to prevent sensitive data from being pushed to the github repo. Changing the file name will require the inclusion of the new file name into .gitignore file.
1. Open the new configuration and make these changes:
    - Replace the two instances of `"subscription-id"` with your appropriate subscription ID. One is located in `"shared-services"` and the other in `"on-premises"`.
    - Replace `"tenant-id"` under `"general"` with your AAD tenant ID.
    - Replace `"deployment-user-id"` with your AAD user object ID.
    - Provide a unique name for `"vdc-storage-account-name"`. This must be a globally unique name since it is used to construct a URI for a structure account. This storage account will reside under `shared-services` subscription.
    - Provide a password value for `"domain-admin-password"`.
1. Save `archetype.json`.

> If you want to know more about the setting, please see the section on [archetype configuration files](../use/configuration-files.adoc).

You are ready to begin your first deployment.

## Running the deployment

Return to your terminal/command-line interface and navigate to the root of the toolkit source.

> We need to execute from the root of the repository in order for the paths used in this tutorial to resolve.

*[Docker]*

`python vdc.py create on-premises -path archetypes/on-premises/archetype.json --upload-scripts`

*[Linux/OSX]*

`python3 vdc.py create on-premises -path archetypes/on-premises/archetype.json --upload-scripts`

*[Windows]:*

`py vdc.py create on-premises -path archetypes/on-premises/archetype.json --upload-scripts`

The toolkit will initiate the deployment and provide status updates.

## Next steps

Now that you have the toolkit setup and have started your first deployment, you should learn about more advanced [usage of the toolkit](../use/readme.md).

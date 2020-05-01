# Getting started with GitHub Actions and the VDC toolkit

#### GitHub Actions are apart of an automation workflow that can integrate with your CI/CD pipeline. Developers can build, test and deploy upon code pushes and pulls to GitHub.
##### To Learn more about GitHub actions visit the [GitHub Action Documentation](https://help.GitHub.com/en/actions)

## GitHub Actions with the VDC toolkit quickstart

### The GitHub action in this repository will create the [Shared Services](../../Environments/SharedServices) Environment and the [MS-VDI](../../Environments/MS-VDI) environment all from a "push" to the GitHub repository.
#### To change the environment being deployed you will need to manipulate the "entrypoint.ps1" file in the root directory. 

### Get started on setting up the action below:
1. #### Ensure you have the latest code when setting up your action pipeline
	- ##### Files you need before proceeding with your actions
		- 'dockerfile' in your root repository
		- 'action.yml' in your root repository
		- 'entrypoint.ps1' in your root repository 
		- 'dockerimage.yml' under the "vdc/.GitHub/workflows" directory
	
2. Create Service Pricipal
 
  	Follow  for creating the service principal and note the object id and password during creation. The service principal will require owner permissions.

- [Create SPN via PowerShell for password based authentication](https://docs.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps?view=azps-3.8.0#password-based-authentication)
- [Create SPN via Azure Cli](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest)
- [Verify & add roles/permissions](https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal)
3. #### You will also need to setup your GitHub secrets for the pipeline to use
	- ##### You will need the following secrets
		- SERVICE_PRINCIPAL
		- SERVICE_PRINCIPAL_PASS
		- DEVOPS_SERVICE_PRINCIPAL_USER_ID
		- ADMIN_USER_NAME
		- ADMIN_USER_PWD
		- DOMAIN_ADMIN_USERNAME
		- DOMAIN_ADMIN_USER_PWD
		- TENANT_ID 
		- SUBSCRIPTION_ID
		- KEYVAULT_MANAGEMENT_USER_ID
		- ADMIN_USER_SSH 
			
	- ##### To add these secrets in your GitHub repository navigate to 
		- "Settings" -> "Secrets"
			- Then add each secret value with exactly the corresponding name above			
		- For more information visit the GitHub link for adding new [Secrets](https://help.GitHub.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets).
		- *You do not need* "" around your secret values. Enter them with raw data.
	
3. #### In your dockerimage.yml file you will need to change the following values that suit your need
	- ORGANIZATION_NAME
	- AZURE_LOCATION
	- Update (optional) "uses: Azure" to your GitHub repo name.
    	- uses: **Azure**/vdc@master
	- Please keep the AZURE_DISCOVERY_URL as is

4. #### Once you have all these changes and updated your GitHub secrets you can push the changes to your repository.

	
5. #### Upon the "push" you will kick off an action which will deploy the shared services and ms-vdi resources. 

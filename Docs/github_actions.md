Getting started with GitHub Actions and the VDC toolkit

	1. Ensure you have the latest code when setting up your action pipeline
		a. Files you need before proceeding with your actions
			i. 'dockerfile' in your root repository
			ii. 'action.yml' in your root repository
			iii. 'entrypoint.ps1' in your root repository 
			iv. 'dockerimage.yml' under the "vdc/.github/workflows" directory
	
	2. You will also need to setup your github secrets for the pipeline to use
		a. You will need the following secrets
			i. SERVICE_PRINCIPAL
			ii. SERVICE_PRINCIPAL_PASS
			iii. DEVOPS_SERVICE_PRINCIPAL_USER_ID
			iv. ADMIN_USER_NAME
			v. ADMIN_USER_PWD
			vi. DOMAIN_ADMIN_USERNAME
			vii. DOMAIN_ADMIN_USER_PWD
			viii. TENANT_ID 
			ix. SUBSCRIPTION_ID
			x. KEYVAULT_MANAGEMENT_USER_ID
			xi. ADMIN_USER_SSH 
			
		b. To add these secrets in your Github repository navigate to 
			i. "Settings" -> "Secrets"
				1) Then add each secret with exactly the name above			
			
		- *You do not need "" around your secret values. 
	
	
	3. In your dockerimage.yml file you will need to change the following values that suit your need
		a. ORGANIZATION_NAME
		b. AZURE_LOCATION
		c. Please keep the AZURE_DISCOVERY_URL as is

	4. Once you have all these changes and updated your Github secrets you can push the changes to your repository. Upon the "push" you will kick off an action which will deploy the shared services and ms-vdi resources. 

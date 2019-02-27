# Deployment validation

As you customize and extend VDC automation toolkit to support your organization's needs, you'll be updating the parameter files and Resource Manager templates included in the example deployments and modules. To ensure that your changes do not break any syntax or formatting rules within the deployment templates, the automation toolkit includes a validation mode.

Validation mode works against the same top-level *azureDeploy.parameters.json* parameter file you create to store your deployment values. This validation mode goes through all the pre-deployment steps a normal deployment would: it processes the parameter files, compiles parameter values into the deployment template, and prepares the required files for submission to the Resource Manager engine. However, in validation mode the deployment processes stops as soon as Resource Manager confirms the submitted files are valid and does not proceed with the actual deployment. 

While a full deployment can take a long time to complete, running a validation pass should only take a few minutes.

**Note**: While the toolkit's validation mode can help you find structural or syntactical issues with your deployment files, it can't detect bad values provided in your parameters files, such as incorrect names or network settings.

## Validation resource dependencies

Although, by default, validation mode will not deploy resources to Azure, certain parts of the validation process may depend on having some resources on the target subscription. For instance, any deployment that creates user accounts that store passwords in a key vault will require a deployed key vault to validate.

Top-level deployment [parameter files](03-parameters-files.md) include the *validation-resource-dependencies* array where these dependencies are defined. Any deployment modules included in this array must already be defined in the *resource-deployment-order* array for that deployment. For the current sample deployment files, the only validation resource dependency is the key vault deployment:

```javascript
    "validation-resource-dependencies": [
        "kv"
    ]
```

When running validation, the toolkit automation script will deploy the resources in the *validation-resource-dependencies* array. If these resources do not exist on the target subscription, they will be created as part of the deployment. If they already exist, they will be redeployed using the latest settings in the parameters file.

Validation resource dependencies are deployed just as they would be during a normal deployment. If one of these resources also has a dependency defined in the parameter file's *resource-dependencies* array, that dependency will also be deployed. For instance, the *kv* resource has a dependency on the *ops* resource, so in validation mode where *kv* is a validation dependency, both *kv* and *ops* resources will be deployed.

## Spoke validation settings

Because deployment validation is meant to work independently of any actually deployed resources, spoke validation may fail when trying to access resources based on parameters set in the hub section of the spoke deployment parameters file. When running validation checks on spoke deployments, temporarily modify your parameters file with the following settings: 

- Set the *hub/deployment-name* parameter to match the *spoke/deployment-name* value.
- Set the *hub/domain-admin-user* parameter to match the *spoke/local-admin-user* value.
- Set the *hub/subscription-id* parameter to match the *spoke/subscription-id* value.

Once validation is complete revert these settings to the correct hub value.

## Run a deployment in validation mode

As discussed in the [launching the main automation script](05-launching-the-main-automation-script.md) section, you can run a deployment in validation mode by passing the *--validate-deployment* argument during any call to the main *vdc.py* script. 

You can validate entire deployments. For example, to validate the entire hub deployment:

[Linux/OSX]

>   *python3 vdc.py hub -path "sample-deployment/contoso-archetypes/hub" --validate-deployment*

[Windows]

>   *py vdc.py hub -path "sample-deployment/contoso-archetypes/hub" --validate-deployment*

You can also validate individual deployment module. For example, to validate the data tier of the spoke-iaas deployment:

[Linux/OSX]

>   *python3 vdc.py spoke -path "sample-deployment/contoso-archetypes/spoke-iaas" -r "sqlserver-alwayson" --validate-deployment*

[Windows]

>   *py vdc.py spoke -path "sample-deployment/contoso-archetypes/spoke-iaas" -r "sqlserver-alwayson" --validate-deployment*

## Clean up dependent resources

After running a validation, you may want to delete any temporary resources created due to the validation's resource dependencies. You can do this by appending the *--delete-validation-resources* when running the validation.

*[Linux/OSX]*

>   *python3 vdc.py validate {environment type} {arguments}*

*[Windows]:*

>   *py vdc.py validate {environment type} {arguments}*

*[Docker]*

>   *python vdc.py validate {environment type} {arguments}*


## Environment types

The enviroment type is either "shared-services", "workload,", or "on-premises" indicating which
type of VDC component you are building out.

## Arguments

There are several required and optional arguments that you can pass for a
deployment:

| **Argument**                          | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|---------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| \--validate-deployment <br>[Optional]     | If this argument is included, the toolkit will attempt to validate the deployment against Azure Resource Manager without actually performing a deployment. For more details on how validation works, see the [deployment validation](11-deployment-validation.md) topic.      |
| \--delete-validation-resources <br>[Optional]   | Validation can have dependencies on certain resources like a Key Vault actually being deployed to your target before the rest of your resource deployment can validate (defined in the validation-resource-dependencies parameter of your [top-level parameters](03-parameters-files.md#general-settings) file). If these dependencies don't exist, the validation process will deploy test versions of the required resources. Using this argument will delete these test resources after validation is complete.

**Note:** Only apply the *--delete-validation-resources* if you have not already created the required validation dependency. If you've already created a key vault as part of deploying your hub virtual network, for instance, and then pass this argument when validating your ADDS resource deployment, you might delete the pre-existing key vault that other resources still depend on.
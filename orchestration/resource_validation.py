from interface import implements
from os.path import dirname, split
from exceptions.custom_exception import CustomException
from orchestration.common import helper
from orchestration.data.blob_storage import BlobStorage
from orchestration.models.content_type import ContentType
from orchestration.integration.cli.aad_client import AADClientCli
from orchestration.integration.cli.keyvault_client import KeyVaultClientCli
from orchestration.integration.sdk.policy_client import PolicyClientSdk
from orchestration.integration.sdk.resource_management_client import ResourceManagementClientSdk
from orchestration.integration.sdk.management_lock_client import ManagementLockClientSdk
from orchestration.ibusiness import BusinessInterface
from orchestration.common.parameter_initializer import ParameterInitializer
from orchestration.data.idata import DataInterface
from orchestration.common.module_version import ModuleVersionRetrieval
from orchestration.models.resource_module import ResourceModule
import json
import sys
import logging

class ResourceValidation(implements(BusinessInterface)):

    _logger = logging.getLogger(__name__)
    _vdc_storage_output_container_name: str = 'output'

    def __init__(
        self,
        data_store: DataInterface,
        management_lock_integration_service: ManagementLockClientSdk,
        resource_management_integration_service: ResourceManagementClientSdk,
        policy_integration_service: PolicyClientSdk,
        aad_cli_integration_service: AADClientCli,
        keyvault_cli_integration_service: KeyVaultClientCli,
        module_version_retrieval: ModuleVersionRetrieval,
        vdc_storage_account_name: str,
        vdc_storage_account_subscription_id: str,
        vdc_storage_account_resource_group: str,
        validate_deployment: bool,
        delete_validation_modules: bool,
        deploy_all_modules: bool,
        deployment_configuration_path: str,
        module_deployment_order: list,
        resource_group: str,
        single_module: str,
        deploy_module_dependencies: bool,
        upload_scripts: bool,
        create_vdc_storage: bool,
        shared_services_deployment_name: str,
        deployment_name: str,
        location: str,
        tenant_id: str,
        subscription_id: str,
        shared_services_subscription_id: str,
        service_principals: list,
        organization_name: str,
        encryption_keys_for: list,
        module_dependencies: list,
        environment_type: str,
        json_parameters: dict,
        import_module: str,
        custom_scripts_path: str,
        environment_keys: dict):

        ''' Class initializer
        
        :param data_store: Data storage instance used by VDC to store deployment outputs and custom scripts
        :type data_store: DataInterface
        :param sdk_integration_service: Integration instance that calls SDK commands
        :type sdk_integration_service: IntegrationInterface
        :param aad_cli_integration_service: Integration instance that calls CLI commands that interacts with AAD
        :type aad_cli_integration_service: ADClientCli
        :param keyvault_cli_integration_service: Integration instance that calls CLI commands that interacts with KeyVault and creates Certificates and Encryption Keys
        :type keyvault_cli_integration_service: KeyVaultClientCli
        :param vdc_storage_account_name: VDC Storage Account Name, storage account that stores scripts and deployment outputs
        :type vdc_storage_account_name: str
        :param vdc_storage_account_subscription_id: Subscription Id where VDC Storage Account resides
        :type vdc_storage_account_subscription_id: str
        :param vdc_storage_account_resource_group: Resource group containing VDC Storage Account resides
        :type vdc_storage_account_resource_group: str
        :param validate_deployment: Indicates whether or not the deployment is running in validation mode
        :type validate_deployment: bool
        :param delete_validation_modules: Indicates whether or not to delete validation modules created during the validation process. Validation modules such as KeyVault
        :type delete_validation_modules: bool
        :param deploy_all_modules: Indicates whether or not all modules are being deployed
        :type deploy_all_modules: bool
        :param deployment_configuration_path: Archetype path containing deployment configuration information
        :type deployment_configuration_path: str
        :param module_deployment_order: List containing modules to be deployed
        :type module_deployment_order: list
        :param resource_group: If passed, all resources will be deployed in this resource group
        :type resource_group: str
        :param single_module: When -r argument is passed, indicates that a single module will getß deployed
        :type single_module: str
        :param deploy_module_dependencies: Indicates whether or not all module dependencies must be deployed first
        :type deploy_module_dependencies: bool
        :param upload_scripts: Indicates whether or not to upload scripts to VDC Storage Account
        :type upload_scripts: bool
        :param create_vdc_storage: Indicates whether or not VDC Storage Account will get created
        :type create_vdc_storage: bool
        :param shared_services_deployment_name: When deploying a shared_services, this value is the same as deployment_name. When deploying a workload, this value will be different
        :type shared_services_deployment_name: str
        :param deployment_name: Deployment name
        :type deployment_name: str
        :param location: Location to use when creating a resource group
        :type location: str
        :param tenant_id: Tenant Id
        :type tenant_id: str
        :param subscription_id: Subscription Id
        :type subscription_id: str
        :param shared_services_subscription_id: Shared Services Subscription Id
        :type shared_services_subscription_id: str
        :param service_principals: List of service principals, this list is used to grant access (by using azure cli) to KeyVault
        :type service_principals: list
        :param organization_name: Organization name
        :type organization_name: str
        :param encryption_keys_for: List used to create KeyVault encryption keys (these values are used in Azure Disk Encryption VM extension)
        :type encryption_keys_for: list
        :param module_dependencies: Main list containing all module dependencies from the main parameter file
        :type module_dependencies: list
        :param environment_type: Deployment type, this could be: Shared Services | Workload | On-premises
        :type environment_type: str
        :param json_parameters: Dictionary representation of main parameters file
        :type json_parameters: dict
        :param import_module: Value of the main module
        :type import_module: str
        :param custom_scripts_path: Custom scripts path
        :type custom_scripts_path: str
        :param environment_keys: Dictionary containing command line argument information
        :type environment_keys: dict

        :raises: :class:`CustomException<Exception>`
        '''
        
        self._default_parameters = dict()        
        self._modules_already_provisioned = list()        
        self._data_store = data_store
        self._resource_management_integration_service = resource_management_integration_service
        self._policy_integration_service = policy_integration_service
        self._management_lock_integration_service = management_lock_integration_service
        self._aad_cli_integration_service = aad_cli_integration_service
        self._keyvault_cli_integration_service = keyvault_cli_integration_service
        self._module_version_retrieval = module_version_retrieval
        self._vdc_storage_account_name = vdc_storage_account_name
        self._vdc_storage_account_subscription_id = vdc_storage_account_subscription_id
        self._vdc_storage_account_resource_group = vdc_storage_account_resource_group
        self._validation_mode_on = validate_deployment
        self._deploy_all_modules = deploy_all_modules
        self._deployment_configuration_path = deployment_configuration_path
        self._module_deployment_order = module_deployment_order
        self._resource_group = resource_group
        self._single_module = single_module
        self._deploy_module_dependencies = deploy_module_dependencies
        self._upload_scripts = upload_scripts
        self._create_vdc_storage = create_vdc_storage
        self._shared_services_deployment_name = shared_services_deployment_name
        self._deployment_name = deployment_name
        self._location = location
        self._tenant_id = tenant_id
        self._subscription_id = subscription_id
        self._shared_services_subscription_id = shared_services_subscription_id
        self._service_principals = service_principals
        self._organization_name = organization_name
        self._encryption_keys_for = encryption_keys_for
        self._module_dependencies = module_dependencies
        self._environment_type = environment_type
        self._json_parameters = json_parameters
        self._import_module = import_module
        self._custom_scripts_path = custom_scripts_path
        self._environment_keys = environment_keys
        self._deployment_prefix = self.get_deployment_prefix(
            self._organization_name,
            self._environment_type,
            self._deployment_name)
        self._module_validation_dependencies = []
        self._validation_resource_groups = []
        self._delete_validation_modules = delete_validation_modules
        self._logger.info("Using the following output parameter deployment prefix: {}".format(
            self._deployment_prefix))
        
    def create(self) -> list:

        '''Main function used to execute a module(s) deployment.

        This function creates a storage repository to place all deployment outputs, and to to place
        custom scripts if --upload-scripts argument passed is set to true.
        :param parameter_initializer: Object containing all required properties used during a module provisioning
        :type parameter_initializer: ParameterInitializer
        :param deployment_path: Path that contains deployment and parameters folders
        :type deployment_path: str
        :raises: :class:`CustomException<Exception>`
        '''
        
        try:            
            
            # Append dummy sas key to default parameters, the key will now be
            # appended to all deploy templates            
            self.append_to_default_parameters(dict(
                {
                    'sas-key': 'xxxxxxxxxx', 
                    'output-params-storage-key': 'xxxxxxxxxx', 
                    'output-params-storage-account-name': 'xxxxxxxxxx'
                }))

            module_names = list()

            if self._deploy_all_modules == True:
                # Let's get all the deployment folders
                module_names = self._module_deployment_order
                self._logger.info('validating all modules:{}'.format(
                    module_names))
            else:
                if self._single_module is None or self._single_module == '':
                    raise CustomException('No module has been passed')

                # Single module, let's add it to the list
                module_names.append(self._single_module)
            
            # Let's create a dummy resource group for the validation to pass
            self._resource_management_integration_service\
                .create_or_update_resource_group(
                        self._resource_group, 
                        self._location)
            
            self._provision_module_validation_dependencies(
                self._module_dependencies)
            
            for module in module_names:
                self._deploy(
                    self._module_dependencies,
                    module, 
                    self._resource_group)

            # Let's prepare to delete resource groups created during the validation process
            self._validation_resource_groups.append(self._resource_group)

            self._logger\
                .info('About to delete the following resource groups: {}'.format(
                self._validation_resource_groups))
            
            for validation_resource_group in self._validation_resource_groups:
                # After the validation, let's delete the dummy resource group
                self._logger\
                    .info('Deleting the following resource group: {}'.format(
                    validation_resource_group))
                self._management_lock_integration_service\
                    .delete_all_resource_group_locks(
                        validation_resource_group)
                self._resource_management_integration_service\
                    .delete_resource_group(
                        validation_resource_group)

            return list()
                    
        except Exception as ex:
            self._logger.error('There was an unhandled error while provisioning the modules.')
            self._logger.error(ex)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise ex

    def _deploy(
        self, 
        all_modules: list,
        module_to_deploy: str,
        resource_group_to_deploy: str = None):

        """Function that analyzes the module to be deployed. If dependencies are found, 
        these will get provisioned first (recursive call), following the deployment order from the 
        main template (module-deployment-order property). 

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_to_deploy: The name of the module to deploy. 
         Resource should exist in deployments/shared_services|workload/ folder (i.e. deployments/shared_services/vnet)
         The name is case sensitive.
        :type module_to_deploy: str (optional)
        :param resource_group_to_deploy: A resource deployment will use this name as resource group.
         If no value is provided, a default name gets created with the following format:
         organizationName-shared-services|workload-module (i.e. contoso-shared-services-net)
        :type resource_group_to_deploy: str
        :raises: :class:`Exception`
        """
        
        self._logger\
            .info('***** validating module: {} *****'.format(
                module_to_deploy.upper()))

        # Find the module and check if there are dependencies, 
        # if yes, execute the dependency provisioning first
        module_found = self.find_module(
             self._module_dependencies,
            module_to_deploy)
            
        if  self._deploy_module_dependencies and \
            module_found is not None and \
            len(module_found._dependencies) > 0:
            
            self._logger\
                .info('dependencies found: {}'.format(
                    module_found._dependencies))
                        
            # Let's sort the dependencies based on module-deployment-order 
            # parameter (from shared_services or workload folder -> /parameters/azureDeploy.parameters.json)
            dependencies = self.sort_module_deployment_list(
                module_found._dependencies)

            for dependency in dependencies:
                self._logger.info('validating dependency: {} on resource group: {}'.format(
                    dependency, 
                    resource_group_to_deploy))

                # Let's deploy all the dependencies recursively
                self._deploy(
                    all_modules,
                    dependency, 
                    resource_group_to_deploy)
        
        create_resource_group = True
        
        # Not need to validate the validation process dependencies again, these got already validated and provisioned
        if module_to_deploy not in self._module_validation_dependencies:
            # Now, let's deploy the module (after a recursive loop or from single module - if no dependencies were found)        
            self._deploy_initial(
                all_modules,
                module_to_deploy, 
                resource_group_to_deploy, 
                create_resource_group)

    def _deploy_initial(
        self, 
        all_modules: list,
        module_to_deploy: str, 
        resource_group_to_deploy: str,
        create_resource_group: bool = True):

        """Main function that executes the module provisioning.

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_to_deploy: The name of the module to deploy. 
         Resource should exist in deployments/shared_services|workload/ folder (i.e. deployments/shared_services/vnet)
         The name is case sensitive.
        :type module_to_deploy: str
        :param resource_group_to_deploy: A resource deployment will use this name as resource group.
         This function creates a resource group if it does not exist.
        :type resource_group_to_deploy: str
        :param create_resource_group: Value to instruct if a resource group will be created.
         By default, a module deployment creates a resource group, but there are two situations 
         where a module will be deployed in an existing resource group:
         1. Nested deployment 
            (in parameters/shared_services|workload/azureDeploy.parameters.json: module-dependencies -> create-resource-group property)
         2. Resource dependency to use dependent resource group 
            (in parameters/shared_services|workload/azureDeploy.parameters.json: module-dependencies -> same-resource-group property)
        :type create_resource_group: bool (optional)
        :raises: :class:`Exception`
        """
        
        if module_to_deploy in self._modules_already_provisioned:
            self._logger\
                .info('{} already provisioned'.format(module_to_deploy))
        else:
            # Add module to list of already provisioned modules
            self._modules_already_provisioned.append(module_to_deploy)
            
            template_file: dict = self.get_deployment_template_contents(
                all_modules,
                module_to_deploy)
            
            parameters_file: dict = self.get_parameters_template_contents(
                all_modules,
                module_to_deploy)
            
            # This function checks if there are dependencies, if yes, the function 
            # appends output parameters from the blob storage into the parameters file and also appends
            # the values from _default_parameters (dict)
            parameters_file = self.append_dependency_parameters(
                        all_modules,
                        module_to_deploy)
            
            # Since we are appending all output parameters coming from a file, there is a chance that not all of
            # the parameters appended are present in the template file.
            # To avoid an exception that a parameter is passed and is not present
            # in the original file, we'll append the parameters that are not present to the template file
            template_file = self.append_parameters_not_present_in_template(
                    parameters_file,
                    template_file)

            if parameters_file is not None:
            
                import copy
                # Replace tokens, if any
                parameters_file = \
                    helper.replace_all_tokens(
                        dict_with_tokens=copy.deepcopy(parameters_file),
                        parameters=self._json_parameters,
                        organization_name=self._organization_name,
                        shared_services_deployment_name=self._shared_services_deployment_name,
                        workload_deployment_name=self._deployment_name,
                        storage_container_name=self._vdc_storage_output_container_name,
                        environment_keys=self._environment_keys,
                        storage_access=self._data_store,
                        validation_mode=self._validation_mode_on)

                # Let's execute operations, if any
                replaced_string = helper.operations(
                    json.dumps(parameters_file), 
                    self._json_parameters)

                parameters_file = \
                    json.loads(replaced_string)
            
            self._logger\
                .info('parameters and deployment files successfully loaded')

            # Execute the deployment
            self._resource_management_integration_service\
                .validate_deployment(
                    mode='Incremental',
                    template=template_file,
                    parameters=parameters_file,
                    resource_group_name=resource_group_to_deploy,
                    deployment_name='{}-deployment-{}'.format(
                        self._deployment_prefix,
                        module_to_deploy))

            # Save output paramaters to Azure storage so that dependent modules can read it
            self._logger.info('***** module deployment validation completed successfully *****')

    def _provision_module_validation_dependencies(
        self,
        all_modules: list):
        """Function that validates and provision validation-module dependencies.
        These modules are required to be provisioned first in order to pass the validation process.
        An example is KeyVault, if KeyVault is referenced in a parameters file (say to retrieve a secret), 
        then validation process expects KeyVault to exist, for this reason, KeyVault needs to be temporally provisioned for
        the validation process to succeed. The module gets temporally created because at the end of the validation process
        the resource group gets deleted.

         This function, besides provisioning the modules, will also append any resource group created to
         the list: _validation_resource_groups, this list is used later to delete all resource groups created

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :raises: :class:`Exception`
        """
        # module-validation-dependencies are modules that get provisioned prior running any validation
        if 'module-validation-dependencies' in self._json_parameters['orchestration'] \
            and len(self._json_parameters['orchestration']['module-validation-dependencies']) > 0:
            self._module_validation_dependencies = \
                self._json_parameters['orchestration']['module-validation-dependencies']
            
            # Let's sort the module-validation-dependencies
            self._module_validation_dependencies = \
                self.sort_module_deployment_list(
                    self._module_validation_dependencies)
                
            self._logger\
                .info('module-validation dependencies found: {}'.format(
                    self._module_validation_dependencies))
        
        if len(self._module_validation_dependencies) > 0:
            for module_validation_dependency in self._module_validation_dependencies:
                
                self._logger.info('module_validation found: {}'.format(
                    module_validation_dependency))

                # Let's get the resource group name
                resource_group_to_deploy = \
                    self._get_resource_group_name(
                        all_modules=all_modules,
                        module_name=module_validation_dependency, 
                        resource_group=None)

                self._logger\
                    .info('resource group to create: {}'.format(
                        resource_group_to_deploy))
                
                # Let's provision the module_validation_dependency dependency resource group
                self._resource_management_integration_service\
                    .create_or_update_resource_group(
                        resource_group_to_deploy, 
                        self._location)

                # Let's run the validation process prior provisioning the module
                self._deploy(
                    all_modules,
                    module_validation_dependency, 
                    resource_group_to_deploy)
                self._logger\
                    .info('module-validation dependencies successfully validated')
            
            self._logger\
                .info('About to provision module-validation dependencies')
            
            # If all succeeded, let's provision the module-validation dependencies (an example of a validation 
            # module dependency is: KeyVault, that is referenced in the parameters file to retrieve secret information for instance)                
            for module_validation_dependency in self._module_validation_dependencies: 
                from orchestration.resource_deployment import ResourceDeployment
                
                # Let's update parameter_initializer to deploy only the module-validation
                deploy_all_modules = False
                single_module = module_validation_dependency
                validate_deployment = True
                deploy_module_dependencies = True
                
                # Invoke deployment and append resulting resource groups created, these RGs 
                # will get deleted
                
                resourceDeployment = ResourceDeployment(
                    self._data_store, 
                    self._resource_management_integration_service,
                    self._policy_integration_service,
                    self._aad_cli_integration_service,
                    self._keyvault_cli_integration_service,
                    self._module_version_retrieval,
                    self._vdc_storage_account_name,
                    self._vdc_storage_account_subscription_id,
                    self._vdc_storage_account_resource_group,
                    validate_deployment,
                    deploy_all_modules,
                    self._deployment_configuration_path,
                    self._module_deployment_order,
                    None,
                    single_module,
                    deploy_module_dependencies,
                    self._upload_scripts,
                    self._create_vdc_storage,
                    self._shared_services_deployment_name,
                    self._deployment_name,
                    self._location,
                    self._tenant_id,
                    self._subscription_id,
                    self._shared_services_subscription_id,
                    self._service_principals,
                    self._organization_name,
                    self._encryption_keys_for,
                    self._module_dependencies,
                    self._environment_type,
                    self._json_parameters,
                    self._import_module,
                    self._custom_scripts_path,
                    self._environment_keys)

                resource_groups_provisioned = \
                    resourceDeployment.create()

                if self._delete_validation_modules:
                    self._validation_resource_groups = \
                        self._validation_resource_groups + resource_groups_provisioned
                     
    def _get_resource_group_name(
        self,
        all_modules: list,
        module_name: str,
        resource_group: str):
        """Function that evaluates a module object's properties to generate a resource group name or use an existing one.
        
        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name: Resource name, this value is used to construct a default resource group
        :type module_name: str
        :param resource_group: Resource group name, if passed, it is used to create a resource group
        :type resource_group: str
        """
        
        module_found = self.find_module(
             all_modules,
             module_name)

        dependent_module_found = \
                self.is_a_dependency_deployable_in_dependent_rg(
                    all_modules,
                    module_name)
        
        # If a resource group value is passed from the command line argument, let's use it
        if resource_group is not None and \
           resource_group != '':
            resource_group_to_deploy = resource_group
        elif dependent_module_found is not None and \
             dependent_module_found._resource_group_name != '':
            # Let's grab the resource-group-name value of the dependent module found
            resource_group_to_deploy = \
                dependent_module_found._resource_group_name
        elif dependent_module_found is not None:
            # Let's create a resource group name based on the dependent module found
            resource_group_to_deploy = \
                self.create_default_resource_group_name(
                    dependent_module_found._module)
        elif module_found is not None and \
             not module_found._create_resource_group:
            
            # Let's use the resource group name of the first dependency found.
            # This is the case when the resource specifies create-resource-group = false.
            # When executing nested deployments, ARM expects a resource group name to be passed
            # (even if the template specifies resource group information). 
            # For this reason, we need to pass a resource group name that exists,
            # to prevent an ARM validation error.
            resource_group_to_deploy = \
                self._get_resource_group_name(
                    all_modules=all_modules,
                    module_name=module_found._dependencies[0],
                    resource_group=None)
        elif module_found is not None and \
             module_found._resource_group_name != '' :
            # Let's grab the resource-group-name value of the module found
            resource_group_to_deploy = module_found._resource_group_name
        else:
            # Let's create a resource group name based on the module found
            resource_group_to_deploy = \
                self.create_default_resource_group_name(
                    module_name)
        
        return resource_group_to_deploy

    def create_vdc_storage(
        self):
        pass

    def get_deployment_template_contents(
        self,
        all_modules: list,
        module_name: str):
        """Function that reads a local folder to fetch a deployment template file.
        
        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name: Resource name used to construct the file path 
        (i.e. /shared_services/deployments/net/azureDeploy.json)
        :type module_name: str

        :raises: :class:`Exception`
        """

        module_found = self.find_module(
            all_modules=all_modules,
            module_to_find=module_name)

        if module_found is None:
            module_found = \
                ResourceModule()\
                .create_default(module_name=module_name)
        
        return self._module_version_retrieval.get_template_file(
            version=module_found._source._version,
            module_name=module_found._module,
            path=module_found._source._template_path)

    def get_parameters_template_contents(
        self,
        all_modules: list,
        module_name: str):
        """Function that reads a local folder to fetch a deployment parameters file.
        
        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name: Resource name used to construct the file path 
        (i.e. parameters/shared_services/net/azureDeploy.json)
        :type module_name: str

        :raises: :class:`Exception`
        """

        module_found = self.find_module(
            all_modules=all_modules,
            module_to_find=module_name)

        if module_found is None:
            module_found = \
                ResourceModule()\
                .create_default(module_name=module_name)

        return self._module_version_retrieval.get_parameters_file(
            version=module_found._source._version,
            module_name=module_found._module,
            path=module_found._source._parameters_path)

    def create_policies(
        self,
        all_modules: list,
        module_name: str=None,
        resource_group_name: str=None,
        is_subscription_policy: bool = False):
        """Function that creates and assigns policies.
        
        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name: Resource name used to construct the file path 
        (i.e. policies/shared_services/net/arm.policies.json)
        :type module_name: str
        :param resource_group_name: Resource group name used in the policy assignment. 
        This value is required when is_subscription_policy is set to True
        :type resource_group_name: str
        :param is_subscription_policy: Instructs the function to assign a policy to a subscription (true)
        or resource group (false)
        :type is_subscription_policy: bool

        :raises: :class:`CustomException`
        """
        pass

    def store_deployment_outputs(
        self,
        container_name: str,
        output_name: str,
        output_content_data: str):
        """Function that stores deployment outputs.

        :param container_name: The name of container where the outputs (in json format) will be placed.        
        :type container_name: str
        :param output_name: Name of the output file
        :type output_name: str
        :param output_content_data: Deployment output data (deserialized json)
        :type output_name: str
        
        :raises: :class:`Exception`
        """
        pass

    def store_custom_scripts(
        self):
        """Function that stores custom scripts (from scripts folder).

        :raises: :class:`Exception`
        """
        pass

    def find_module(
        self,
        all_modules: list,
        module_to_find: str) -> ResourceModule:
        """Function that returns a module from parameters/shared_services|workload/azureDeploy.parameters.json -> module-dependencies

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_to_find: Resource name to find in module-dependencies
        :type module_to_find: str
        
        :return: module or None if no module was found
        :rtype: dict
        :raises: :class:`Exception`
        """

        strongly_typed_modules = \
            list(map(ResourceModule, all_modules))
        
        resource_module: ResourceModule = None

        for resource_module in strongly_typed_modules:
            if resource_module._module == module_to_find:
                return resource_module
        
        # If not found, return None
        return None

    def find_dependencies(
        self,
        all_modules: list,
        module_to_find: str) -> list:
        """Function that returns module dependencies, if any (parameters/shared_services|workload/azureDeploy.parameters.json -> module-dependencies -> dependencies)

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name_to_find: Resource name to analyze if dependencies property contains any values
        :type module_name_to_find: str
        
        :return: module dependencies or None if no values were found
        :rtype: dict
        :raises: :class:`Exception`
        """

        module_found = self.find_module(
                            all_modules=all_modules,
                            module_to_find= module_to_find)

        if  module_found is not None and\
            len(module_found._dependencies) > 0:
            return module_found._dependencies
        else:
            return None

    def append_dependency_parameters(
        self,
        all_modules: list,
        module_name: str):
        """Function that appends dependency parameters to parameters file. If a module contains
        dependencies (module-dependencies -> dependencies) and these dependencies generated an
        output, then these values get appended to the parameters file.
        This is similar to a linked template where the deployment contains 
        outputs [reference('<name-of-deployment>').outputs.<property-name>.value].

        This function also appends the values from _default_parameters. 
        By default there are three
        values:
         {
            'sas-key': sas_key, 
            'output-params-storage-key': storage_account_key, 
            'output-params-storage-account-name': self._vdc_storage_account_name
         }

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name: Resource name used to construct the parameters file path        
        :type module_name: str
        :param template_file_contents: Template file deserialized
        :type template_file_contents: str
        
        :return: deployment parameters
        :rtype: dict
        :raises: :class:`Exception`
        """
        dependencies = self.find_dependencies(
            all_modules=all_modules,
            module_to_find=module_name)
        
        parameters_file_contents = \
            self.get_parameters_template_contents(
                all_modules,
                module_name)
        
        # Let's initialize the dict if a file does not exists
        if parameters_file_contents is None:
            parameters_file_contents = dict()
        
        if dependencies is not None and len(dependencies) > 0:    
            
            self._logger\
                .info("appending dependency output parameters to parent: {}".format(
                module_name))

            for module_dependency in dependencies: 
                
                template_file = self.get_deployment_template_contents(
                    all_modules,
                    module_dependency)
                
                if 'outputs' in template_file:
                    output_data = template_file['outputs']
                    
                    output_parameters = dict()
                    # Outputs format is as follows:
                    # "default-subnet-nsg-id": {
                    #    "type": "string",
                    #    "value": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('nsg-name'))]"
                    # },
                    for dictKey, dictValue in output_data.items():
                        # dictValue contains the value object (from above -> type and value properties) this is why we use dictValue['value']
                        # to fetch the actual value of "value" property
                        output_parameters.update({
                            dictKey : {
                                "value": self.get_default_value(dictValue['type']) 
                            }
                        })

                    # Let's append the output parameters to the parameters file
                    parameters_file_contents.update(output_parameters)

            # Let's append the values from _default_parameters (i.e. storage sas key
            # storage account name, etc.)
        parameters_file_contents.update(self._default_parameters)

        return parameters_file_contents

    def get_default_value(
        self,
        type: str):

        if type.lower() == 'string':
            return "vdc-validation-test-rg"
        elif type.lower() == 'int':
            return 1
        else:
            return ""

    def is_a_dependency_deployable_in_dependent_rg(
        self, 
        all_modules: list,
        module_to_find: str) -> ResourceModule:
        """Function that evaluates if a module dependency will be deployed in a dependent resource group.
        If parameters/shared_services|workload/azureDeploy.parameters.json -> module-dependencies -> same-resource-group is set to true, it means
        that the dependencies will be deployed in the dependent resource group

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_to_find: Resource to find in dependencies property
         parameters/shared_services|workload/azureDeploy.parameters.json -> module-dependencies -> dependencies
        :type module_to_find: str

        :raises: :class:`Exception`
        """

        # Let's get all the modules
        
        strongly_typed_modules = \
            list(map(ResourceModule, all_modules))

        resource_module: ResourceModule = None

        for resource_module in strongly_typed_modules:
            
            # Let's analyze the dependencies
            dependencies = resource_module._dependencies
            
            if  len(dependencies) > 0 and\
                module_to_find in dependencies and\
                resource_module._same_resource_group:
                
                self._logger.info(
                    'Provision dependencies in same resource group as {} module'.format(resource_module._module))
                
                # Dependency found, and has same-resource-group flag 
                # set to True
                return resource_module

        return None

    def get_deployment_prefix(
        self,        
        organization_name: str,
        environment_type: str,
        deployment_name: str):
        """Constructs a default deployment prefix value using the following format:
        OrganizationName-Shared-Services|Workload (i.e. contoso-shared-services)

        :param organization_name: The organization name to be used.
        :type organization_name: str
        :param environment_type (optional): The deployment type to be used (shared_services or workload).         
        :type environment_type: str
        :param deployment_name (optional): The deployment name to be used.         
        :type deployment_name: str

        :return: deployment prefix
        :rtype: str
        :raises: :class:`Exception`
        """

        return '{}-{}-{}'.format(
                organization_name,
                environment_type,
                deployment_name)

    def append_to_default_parameters(
        self, 
        args : dict):
        """Appends parameters to a global variable called _default_parameters.
        _default_parameters is a dictionary that gets appended on every module deployment.
        Make sure to add these values to the deployment template

        :param args: The parameters to be appended to _default_parameters.
        :type args: dict

        :raises: :class:`Exception`
        """

        for arg in args:
            self._logger.debug("Appending: {}, Value: {}".format(arg, args[arg]))
            self._default_parameters[arg] = {'value': args[arg]}

    def sort_module_deployment_list(
        self, 
        module_list: list):
        """Function that sorts all modules based on module-deployment-order

        :param module_list: List of unsorted modules.
        :type module_list: list

        :return: sorted list
        :rtype: list
        :raises: :class:`Exception`
        """

        if self._module_deployment_order is not None and module_list is not None:
            module_list = helper.sort_module_deployment(
                module_list,
                self._module_deployment_order)
        
        return module_list

    def create_default_resource_group_name(
        self, 
        module_name: str):
        """Function that creates a default resource group name using the following format:
        OrganizationName-Shared-Services|Workload-Resource-rg (i.e. contoso-shared-services-net-rg)

        :param module_name: Resource name to be used as part of the resource group name.
        :type module_name: str

        :return: resource group name
        :rtype: str
        :raises: :class:`Exception`
        """

        return '{}-{}-{}-rg'.format(
                        self._organization_name,
                        self._deployment_name,
                        module_name)

    def append_parameters_not_present_in_template(
        self,
        parameters_to_append: dict,
        template_file: dict):
        """Function that evaluates what are the parameters coming from a dependency - output
        that do not exist in the template file, and proceeds to append them temporally (these missing parameters
        do not get persisted), this function ensures that ARM won't throw an exception due to missing
        parameters in the original template.

        :param parameters_to_append: Parameters to be appended
         The ones not present in template_file will get appended
        :type parameters_to_append: dict
        :param template_file: Template file serialized
        :type template_file: dict
        
        :return: deployment template
        :rtype: dict
        :raises: :class:`Exception`
        """

        parameters_from_template = template_file['parameters']
        paremeters_not_present = [item for item in parameters_to_append if item not in parameters_from_template]
        
        # Now let's append the parameters that are not present using a default format
        for paremeter_not_present in paremeters_not_present:
           
            paremeter_not_present_value = parameters_to_append[paremeter_not_present]['value'] if 'value' in parameters_to_append[paremeter_not_present] else 'vdc'
            paremeter_not_present_type = parameters_to_append[paremeter_not_present]['type'] if 'type' in parameters_to_append[paremeter_not_present] else 'string'
            
            template_file['parameters'].update({
                paremeter_not_present : {
                    "defaultValue": paremeter_not_present_value,
                    "type": paremeter_not_present_type
                }
            })

        return template_file
from interface import implements
from os.path import dirname, split
from exceptions.custom_exception import CustomException
from orchestration.common import helper
from orchestration.data.blob_storage import BlobStorage
from orchestration.models.content_type import ContentType
from orchestration.integration.sdk.policy_client import PolicyClientSdk
from orchestration.integration.sdk.resource_management_client import ResourceManagementClientSdk
from orchestration.integration.cli.aad_client import AADClientCli
from orchestration.integration.cli.keyvault_client import KeyVaultClientCli
from orchestration.ibusiness import BusinessInterface
from orchestration.common.parameter_initializer import ParameterInitializer
from orchestration.data.idata import DataInterface
from orchestration.models.resource_module import ResourceModule, ResourceSource
from orchestration.common.module_version import ModuleVersionRetrieval
from orchestration.common.local_file_finder import LocalFileFinder
from orchestration.common.remote_file_finder import RemoteFileFinder
import json
import sys
import logging

class ResourceDeployment(object):
    _logger = logging.getLogger(__name__)
    _vdc_storage_output_container_name: str = 'output'
    _resource_groups_provisioned = ['']
    
    def __init__(
        self,
        data_store: DataInterface,
        resource_management_integration_service: ResourceManagementClientSdk,
        policy_integration_service: PolicyClientSdk,
        aad_cli_integration_service: AADClientCli,
        keyvault_cli_integration_service: KeyVaultClientCli,
        module_version_retrieval: ModuleVersionRetrieval,
        vdc_storage_account_name: str,
        vdc_storage_account_subscription_id: str,
        vdc_storage_account_resource_group: str,
        validate_deployment: bool,
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
        environment_keys: dict,
        from_integration_test: bool = False):

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
        :param environment_type: Deployment type, this could be: Shared-Services | Workload | On-premises
        :type environment_type: str
        :param json_parameters: Dictionary representation of main parameters file
        :type json_parameters: dict
        :param import_module: Main module path
        :type import_module: str
        :param custom_scripts_path: Custom scripts path
        :type custom_scripts_path: str
        :param environment_keys: Dictionary containing command line argument information
        :type environment_keys: dict
        :param from_integration_test: If enabled, the deployment name does not append current milliseconds as part of the deployment name
        :type from_integration_test: bool


        :raises: :class:`CustomException<Exception>`
        '''
        
        self._default_parameters = dict()        
        self._data_store = data_store
        self._resource_management_integration_service = resource_management_integration_service
        self._policy_integration_service = policy_integration_service
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
        self._from_integration_test = from_integration_test
        self._deployment_prefix = self.get_deployment_prefix(
            self._organization_name,
            self._environment_type,
            self._deployment_name)

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
        :return param resource_groups_provisioned: A list containing all
        the resource groups provisioned
        :return type list
        :raises: :class:`CustomException<Exception>`
        '''

        try:
            
            if self._create_vdc_storage:
                self.create_vdc_storage()            
            
            if self._upload_scripts:
                self.store_custom_scripts()
           
            sas_key = self.get_sas_key()

            storage_account_key = \
                self._data_store.get_storage_account_key()
            
            # Append sas key to default parameters, the key will now be
            # appended to all deploy templates            
            self.append_to_default_parameters(dict(
                {
                    'sas-key': sas_key, 
                    'output-params-storage-key': storage_account_key, 
                    'output-params-storage-account-name': self._vdc_storage_account_name
                }))

            # If validation process invoked the module deployment, then validation_mode_on will be True.
            # If true, do not create policies at the subscription level
            if not self._validation_mode_on:
                self._logger.info('***** creating policies at subscription level *****')

                # Create and assign subscription policies
                self.create_policies(
                    all_modules=self._module_dependencies,
                    is_subscription_policy=True)

                self._logger.info('***** policy creation completed successfully *****')

            module_names = list()

            if self._deploy_all_modules == True:
                # Let's get all the deployment folders
                module_names = self._module_deployment_order
            else:
                if self._single_module is None or self._single_module == '':
                    raise CustomException('No module has been passed')

                # Single module, let's add it to the list
                module_names.append(self._single_module)
            
            self._logger.info('deploying modules:{}'.format(
                    module_names))

            all_resource_groups_provisioned = list()
            
            for module in module_names:    
                resource_groups_provisioned = \
                    self._deploy(
                            self._module_dependencies,
                            module,
                            self._resource_group)
                all_resource_groups_provisioned = \
                    all_resource_groups_provisioned +\
                    resource_groups_provisioned
                
            return all_resource_groups_provisioned

        except Exception as ex:
            self._logger.error('There was an unhandled error while provisioning the modules.')
            self._logger.error(ex)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise ex

    def _deploy(
        self, 
        all_modules: list,
        module_to_deploy: str,
        all_resource_groups_provisioned: list = None,
        resource_group_to_deploy: str = None) -> list:

        """Function that analyzes the module to be deployed. If dependencies are found, 
        these will get provisioned first (recursive call), following the deployment order from the 
        main template (module-deployment-order property). 

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_to_deploy: The name of the module to deploy. 
         Resource should exist in deployments/shared_services|workload/ folder (i.e. deployments/shared_services/vnet)
         The name is case sensitive.
        :type all_modules: list
        :param all_resource_groups_provisioned: Accumulator list, this list is used to accumulate results when executing a recursive call
        :type all_resource_groups_provisioned: list
        :param resource_group_to_deploy: A resource deployment will use this name as resource group.
         If no value is provided, a default name gets created with the following format:
         organizationName-shared-services|workload-module (i.e. contoso-shared-services-vnet)
        :type resource_group_to_deploy: str
        :raises: :class:`Exception`
        """
        
        self._logger\
            .info('***** provisioning {} module *****'.format(
                module_to_deploy.upper()))
        
        if all_resource_groups_provisioned is None:
            all_resource_groups_provisioned = list()
        
        module_found = self.find_module(
             all_modules,
             module_to_deploy)
        
        # If there are dependencies execute the 
        # dependency provisioning first
        if  self._deploy_module_dependencies and \
            module_found is not None and \
            len(module_found._dependencies) > 0:
            
            self._logger.info('dependencies found: {}'.format(
                module_found._dependencies))
            
            # Let's sort the dependencies based on module-deployment-order 
            # parameter (from shared_services or workload folder -> /parameters/azureDeploy.parameters.json)
            dependencies = self.sort_module_deployment_list(
                module_found._dependencies)
            
            # Provision dependencies first (recursively)
            for dependency in dependencies:
                self._logger.info('provisioning dependency: {}'.format(
                    dependency))
                
                # Let's deploy all the dependencies recursively
                resource_groups_provisioned = list()
                resource_groups_provisioned = \
                    self._deploy(
                            all_modules,
                            dependency, 
                            all_resource_groups_provisioned,
                            resource_group_to_deploy)
                resource_groups_provisioned = \
                    [resource_group for resource_group in resource_groups_provisioned \
                        if resource_group not in all_resource_groups_provisioned]
                
                all_resource_groups_provisioned = \
                    all_resource_groups_provisioned + resource_groups_provisioned

        from orchestration.integration.custom_scripts.script_execution import CustomScriptExecution
        
        # If module is of type Bash or Powershell,
        # execute custom script
        if  module_found is not None and\
            module_found._type != '' and\
            module_found._type is not None:
            
            self._logger\
                .info('***** provisioning {} custom script *****'.format(
                    module_found._module.upper()))

            script_execution = CustomScriptExecution()
            result = script_execution.execute(
                script_type=module_found._type,
                command=module_found._command,
                output_file_path=module_found._output_file,
                property_path=module_found._property_path,
                file_path_to_update=self._deployment_configuration_path)
            
            if module_found._property_path is not None and\
               len(module_found._property_path) > 0:
                self._json_parameters = \
                    helper.modify_json_object(
                        prop_value=result,
                        prop_key=module_found._property_path,
                        json_object=self._json_parameters)

            all_resource_groups_provisioned.append(
                    module_found._module)
        else:
            resource_group_to_deploy = \
            self._get_resource_group_name(
                all_modules,
                module_to_deploy,
                resource_group_to_deploy)
            
            self._logger\
                .info(
                    'Module: {} to be provisioned using resource group: {}'.format(
                        module_to_deploy, 
                        resource_group_to_deploy))
            
            # Now, let's deploy the module (after a recursive loop or from single module - if no dependencies were found)        
            self._deploy_initial(
                all_modules,
                module_to_deploy,
                resource_group_to_deploy)

            if resource_group_to_deploy not in all_resource_groups_provisioned:
                all_resource_groups_provisioned.append(
                    resource_group_to_deploy)
            
        return all_resource_groups_provisioned

    def _deploy_initial(
        self, 
        all_modules: list,
        module_to_deploy: str, 
        resource_group_to_deploy: str):

        """Main function that executes the module provisioning.

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_to_deploy: The name of the module to deploy. 
         Resource should exist in deployments/shared_services|workload/ folder (i.e. deployments/shared_services/vnet)
         The name is case sensitive.
        :type module_to_deploy: str
        :param resource_group_to_deploy: Resource group that will contain the module to deploy.
         This function creates a resource group if it does not exist.
        :type resource_group_to_deploy: str
        :raises: :class:`Exception`
        """
        
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

        self._logger.info('parameters and deployment files successfully loaded')

        # Provision a resource group if it does not exist
        if not self._resource_management_integration_service\
                   .resource_group_exists(
                        resource_group_to_deploy):

            self._logger\
                .info('creating resource group: {}, for module: {}'.format(
                resource_group_to_deploy, module_to_deploy))
            self._logger\
                .info('resource group location: {}'.format(self._location))

            self._resource_management_integration_service\
                .create_or_update_resource_group(
                    resource_group_to_deploy, 
                    self._location)
        
        self._logger\
            .info('***** creating policies for module: {} *****'.format(
            module_to_deploy))

        # Let's apply policies at the resource group level
        self.create_policies(
            all_modules=all_modules,
            module_name=module_to_deploy, 
            resource_group_name=resource_group_to_deploy,
            is_subscription_policy=False)

        self._logger.info('***** policy creation completed successfully *****')

        self._logger.info('***** executing {} module deployment *****'.format(
            module_to_deploy.upper()))

        deployment_name = '{}-deployment-{}'.format(
            self._deployment_prefix,
            module_to_deploy)

        # If we are not running integration tests, then let's
        # create unique deployment names
        if not self._from_integration_test:
            deployment_name = '{}-{}'.format(
                deployment_name,
                helper.get_current_time_milli())

            if len(deployment_name) > 60:
                deployment_name = \
                    helper\
                        .create_unique_string(
                            original_value=deployment_name,
                            max_length=60)
            
        # Execute the deployment
        deployment_result = \
            self._resource_management_integration_service\
                .create_or_update_deployment(
                    mode='Incremental',
                    template=template_file,
                    parameters=parameters_file,
                    resource_group_name=resource_group_to_deploy,
                    deployment_name=deployment_name)

        # Save output paramaters to Azure storage so that dependent modules can read it
        self._logger.info('***** module deployment completed successfully *****')

        if deployment_result is not None:
            
            self._logger.debug('saving output parameters')

            file_name = self.create_output_content_name(
                module_to_deploy)
                            
            output_data = json.dumps(deployment_result)

            self._logger.debug('container name:{}, blob name:{}'.format(
                self._vdc_storage_output_container_name,
                file_name))

            self.store_deployment_outputs(
                container_name=self._vdc_storage_output_container_name,
                output_name=file_name,
                output_content_data=helper.cleanse_output_parameters(output_data))

        # KV Custom code
        if (module_to_deploy == 'shared-services-kv' or module_to_deploy == 'workload-kv')\
             and 'encryption-keys-for' in self._json_parameters[self._environment_type] \
             and len(self._json_parameters[self._environment_type]['encryption-keys-for']) > 0:
            # Let's create a service principal
            kv_name = deployment_result['kv-name']['value']

            # Let's check if _service_principals list is not empty
            if self._service_principals is not None and len(self._service_principals) > 0:
                self.set_service_principals_kv_access_policies(kv_name)

            self.create_aad_service_principal(kv_name)
            self._logger.debug('finished the creation of an aad principal')

            # Let's create the encryption keys and append to the kv output parameter file
            self.create_encryption_keys(kv_name)                    
            self._logger.debug('finished the creation of encryption keys')

        self._logger.debug('{} successfully provisioned'.format(module_to_deploy))

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

    def create_vdc_storage(self):
        """Function that creates a vdc storage to store deployment outputs and custom scripts.

        :raises: :class:`Exception`
        """
        self._logger.info('creating vdc storage')
        self._data_store.create_storage()

    def get_deployment_template_contents(
        self,
        all_modules: list,
        module_name: str):
        """Function that reads a local folder to fetch a deployment template file.
        
        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name: Resource name used to construct the file path 
        (i.e. /modules/shared-services-net/v1/azureDeploy.json)
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
        (i.e. modules/shared_services-net/azureDeploy.parameters.json)
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
        is_subscription_policy: bool = True):
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

        self._logger.info("Creating policies")
       
        # Let's get policy files
        if is_subscription_policy:
            scope = '/subscriptions/{}'.format(
                self._subscription_id)
            
            policy_file =\
             self._module_version_retrieval\
                 .get_policy_file(
                    version=None,
                    module_name='policies/subscription',
                    subscription_policy=True,
                    fail_on_not_found=False)
    
        else:
            if resource_group_name is None or resource_group_name == '':
                raise CustomException('resource group name cannot be empty when assigning a policy to a resource group')

            scope = '/subscriptions/{}/resourceGroups/{}'.format(
                self._subscription_id,
                resource_group_name)

            module_found = self.find_module(
            all_modules=all_modules,
            module_to_find=module_name)

            if module_found is None:
                module_found = \
                    ResourceModule().create_default(
                        module_name=module_name)

            policy_file =\
             self._module_version_retrieval.get_policy_file(
                version=module_found._source._version,
                module_name=module_found._module,
                path=module_found._source._policy_path,
                fail_on_not_found=False)
        
        if policy_file is not None:
            
            # Replace tokens, if any    
            replaced_policies = helper.replace_string_tokens(
                        json.dumps(policy_file['policies']),
                        self._json_parameters,
                        self._organization_name,
                        self._shared_services_deployment_name,
                        self._deployment_name,
                        'output',
                        self._data_store,
                        validation_mode=self._validation_mode_on)
            
            # Let's apply the different policies            
            self._policy_integration_service\
                .create_and_assign_policy(
                    scope,
                    json.loads(replaced_policies),
                    self._json_parameters)
        else:
            self._logger.warning('No policy found for: {}'.format(module_name))
        
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
        
        self._logger.debug('saving output parameters in blob storage')
        
        self._data_store.store_contents(
            content_type=ContentType.TEXT,
            container_name=container_name,
            content_name=output_name,
            content_data=output_content_data)

    def store_custom_scripts(self):
        """Function that stores custom scripts (from scripts folder).

        :raises: :class:`Exception`
        """
        
        cutom_scripts_path = \
                helper.retrieve_path(self._custom_scripts_path)

        pathlist = \
            LocalFileFinder()\
            .get_all_folders_and_file_names(
                cutom_scripts_path)

        for path in pathlist:

            # Path is an object not string
            path_in_str = str(path)            
            dir_name = dirname(path_in_str)
            folder_name = split(dir_name)[1]            
            file_name = split(path_in_str)[1]            
            file_name = '{}/{}'.format(folder_name, file_name)             

            self._logger.info('uploading script file name: {} from local path: {}'.format(
                file_name,
                path))

            self._data_store.store_contents(
                content_type=ContentType.FILE,
                container_name='scripts',
                content_name=file_name,
                content_path=path)

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
            
            self._logger.info("appending dependency output parameters to parent: {}".format(
                module_name))

            content_name = ''
            
            for module_dependency in dependencies: 
                
                module_found = \
                    self.find_module(
                        all_modules=all_modules,
                        module_to_find=module_dependency)

                # If type is not none, it means that the module
                # is a custom script module. 
                # For deployment modules type is None 
                if module_found is not None and\
                    module_found._type is not None:
                    continue
                
                content_name = self.create_output_content_name(
                    module= module_dependency)

                self._logger.info("appending dependency output parameter. Blob name: {}".format(
                    content_name))

                output_parameters = self._data_store.get_contents(
                    content_type=ContentType.TEXT,
                    container_name=self._vdc_storage_output_container_name,
                    content_name=content_name)
                
                output_parameters_json = json.loads(output_parameters)

                # Let's append the output parameters to the parameters file
                parameters_file_contents.update(output_parameters_json)

            # Let's append the values from _default_parameters (i.e. storage sas key
            # storage account name, etc.)
        parameters_file_contents.update(self._default_parameters)

        return parameters_file_contents

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

    def find_module(
        self,
        all_modules: list,
        module_to_find: str) -> ResourceModule:
        """Function that returns a module from parameters/shared_services|workload/azureDeploy.parameters.json -> module-dependencies

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param all_modules: Array of dictionaries containing all module-dependencies
        :type all_modules: list
        :param module_to_find: Resource name to find in module-dependencies
        :type module_to_find: str
        
        :return: module or None  if no module was found
        :rtype: ResourceModule
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

    def create_output_content_name(
        self,
        module: str,
        environment_type: str = None,
        deployment_name: str = None):
        """Function that creates a default output content path using the following format:
        '{OrganizationName-DeploymentType-DeploymentName}/parameters/{Resource}/azureDeploy.parameters.output.json'
        (i.e. contoso-shared-services/parameters/net/azureDeploy.parameters.output.json).
        If environment_type and deployment_name are passed, it overrides the default deployment_prefix name.

        :param module: Resource name to be used as part of the path
        :type module: str
        :param environment_type (optional): If passed, overrides the current environment_type (Shared-Services, Workload or On-Premises)
         There are situation where using the current deployment type needs to be overridden, for this case,
         pass a value as deploy_type. 
         If no value is passed, then the function uses the current environment_type
         to construct the path.
        :type environment_type: str
        
        :return: output parameters path
        :rtype: str
        :raises: :class:`Exception`
        """

        # Let's set the default deployment prefix -> [OrgName]-[Deployment-Type]
        deployment_prefix = self._deployment_prefix
        if environment_type is not None and deployment_name is not None:
            # Let's construct the name based on the deployment type passed.
            deployment_prefix = self.get_deployment_prefix(                
                self._organization_name,
                environment_type,
                deployment_name)

        return '{}/parameters/{}/azureDeploy.parameters.output.json'.format(
                deployment_prefix,
                module)

    def get_sas_key(self):
        """Returns the VDC Storage Account SAS key.
        
        :raises: :class:`Exception`
        """

        self._logger.debug('getting sas key for storage name: {} and resource group: {}'.format(self._vdc_storage_account_name, self._vdc_storage_account_resource_group))
        return self._data_store.get_sas_key()

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

    def create_aad_service_principal(
        self,
        kv_name: str):
        '''Function to establish an aad principle within the tenant.
        This function creates a service principle application within the add tenant,
        with an associated certificate that is stored inside a prescribed key vault.

        The deployment user must have certificate access priveledges within the
        key vault resource.

        It also adds the established principle to the access control
        list of the utilised key vault, for future management operations.

        :param kv_name: The name of the key vault resource used.
        :type kv_name: str

        :return: The id of the add application principal (aad_app_id)
        :rtype: str
        :raises: :class:`Exception`
        '''

        name_prefix = '{}-{}'.format(
            self._organization_name, self._deployment_name)
        aad_app_name = '{}-app'.format(name_prefix)
        aad_cert_name = '{}-cert'.format(aad_app_name)

        try:

            # Check if the service principle already exists.
            #--------------------------------------------------------------------------------
            
            json_aad_app_list = self._aad_cli_integration_service.get_aad_sp(
                service_principal_name=aad_app_name)
            
            # Check if the command returned an application definition.
            if len(json_aad_app_list) <= 0:

                # Create a new aad application service principle.
                #-----------------------------------------------------------------------------

                # Convert the output to json.
                json_aad_app = self._aad_cli_integration_service.create_aad_sp(
                    service_principal_name=aad_app_name,
                    kv_name=kv_name,
                    cert_name=aad_cert_name)

            else:

                # Use existing service principle.
                #-----------------------------------------------------------------------------

                # Get the app details from the cehck commands returned list.
                json_aad_app = json_aad_app_list[0]

                # Create a new certificate in case this is a new key vault instance.
                #-----------------------------------------------------------------------------

                self._logger.info('Resetting the certificate credentials for {}.'.format(
                    aad_app_name))

                self._aad_cli_integration_service.reset_aad_sp_credentials(
                    service_principal_name=aad_app_name,
                    kv_name=kv_name,
                    cert_name=aad_cert_name)

            # Get the app id.
            if 'appId' not in json_aad_app:
                raise ValueError(
                    "The aad app details does not contain an 'appId' field.")
            aad_app_id = json_aad_app['appId']

        except Exception as e:            
            self._logger.error('It was not possible establish an aad service principle.')
            self._logger.error('The following error occurred: ' + str(e))            
            self._logger.error(e)
            raise(e)
        try:

            # Add Principal To Key Vault
            #-----------------------------------------------------------------------------
            self._keyvault_cli_integration_service.set_aad_sp_kv_access(
                kv_name=kv_name,
                service_principal_id=aad_app_id)

        except Exception as e:            
            self._logger.error('It was not possible add the service principle to key vault.')
            self._logger.error('The following error occurred: ' + str(e))
            raise(e)

        # Create new outputs to be stored
        additional_outputs = dict()
        additional_outputs['aad-principal-cert-name'] = aad_cert_name
        additional_outputs['aad-principal-id'] = aad_app_id

        # Let's get certificate information
        aad_certificate_url, aad_certificate_thumb = self.certificate_information_extraction(
            kv_name, 
            aad_cert_name)

        # Let's append new certificate information
        additional_outputs['aad-certificate-url'] = aad_certificate_url
        additional_outputs['aad-certificate-thumb'] = aad_certificate_thumb

        # Save output in kv blob storage
        self.append_parameters_to_existing_storage(
            module='kv',
            additional_output_parameters=additional_outputs)

        return aad_app_id

    def create_encryption_keys(
        self,
        kv_name: str):
        '''Function that reads parameters/shared_services|workload/azureDeploy.parameters.json -> encryption-keys-for property,
        loops through the list to create encryption keys in KeyVault. 
         All the encryption keys created will get appended to the existing 
         KeyVault output parameter file.'

        :param kv_name: The name of the key vault resource used.
        :type kv_name: str

        :raises: :class:`Exception`
        '''

        if self._encryption_keys_for is not None and len(self._encryption_keys_for) > 0:

            key_names = dict()
            for encryption_key_name in self._encryption_keys_for:
                key_name = '{}-key'.format(                    
                    encryption_key_name)
                
                key_id = self.create_encryption_key(
                    key_name, 
                    kv_name)
                
                key_names[key_name] = key_id
                        
            # Save output in kv blob storage
            self.append_parameters_to_existing_storage(
                module='kv',
                additional_output_parameters=key_names)

    def create_encryption_key(
        self,
        key_name: str, 
        kv_name: str):

        '''Function to create an encryption key and store it within key vault.

        This function creates a new encyption key and stores it within key vault. This function is intended
        to be used when creating newly encrypted virtual machines.

        :param key_name: The name of the key to be created.
        :type key_name: str
        :param kv_name: The name of the key vault resource to be used.
        :type kv_name: str

        :return: The id of the newly created key (key_id)
        :rtype: str
        :raises: :class:`Exception`
        '''

        self._logger.debug('Creating a new encryption key.')

        # Create encryption key.
        #-----------------------------------------------------------------------------

        try:
            
            key_id = self._keyvault_cli_integration_service.create_kv_encryption_keys(
                key_name=key_name,
                kv_name=kv_name)

            return key_id

        except ValueError as e:
            
            self._logger.error('It was not possible to create the {}{} key.'.format(
                self._environment_type, key_name))
            self._logger.error('The following error occurred: ' + str(e))
            raise(e)

    def set_service_principals_kv_access_policies(
        self,
        kv_name: str):

        '''Function to set access policies within key vault.
        KeyVault provisioning creates encryption keys and certificates, if the user running the deployment
        is a Service Principal, this function will set the right accessPolicies. 
        Currently ARM template - accessPolicies does not allow a Service Principal to be set
           
        :param kv_name: The name of the KeyVault.
        :type kv_name: str
        '''

        # Create encryption key.
        #-----------------------------------------------------------------------------

        try:
            
            if self._service_principals is not None and len(self._service_principals) > 0:

                for service_principal in self._service_principals:
                    output = self._aad_cli_integration_service.set_aad_sp_kv_access(
                        kv_name=kv_name,
                        service_principal_id=service_principal)

                    self._logger.debug('The assign access policies command executed successfuly, producing the following output: {}'
                            .format(output))            
        
        except ValueError as e:
            
            self._logger.error('It was not possible to assign access policies the keyVault: {}.'.format(kv_name))
            self._logger.error('The following error occurred: ' + str(e))
            raise(e)

    def append_parameters_to_existing_storage(
        self,
        module: str,
        additional_output_parameters: dict,
        environment_type: str = None,
        deployment_name: str = None):
        '''Function that appends parameters to existing storage content file

        :param module: The module name, used to locate the content storage folder
        :type module: str
        :param additional_output_parameters: Parameters to append
        :type additional_output_parameters: dict
        :param environment_type (optional): If passed, it overrides the default deployment_prefix name (i.e. Organization-DeploymentType-DeploymentName)
        :type environment_type: str
        :param deployment_name (optional): If passed, it overrides the default deployment_prefix name (i.e. Organization-DeploymentType-DeploymentName)
        :type deployment_name: str
        '''

        # Get content name
        content_name = self.create_output_content_name(
            module=module, 
            environment_type=environment_type,
            deployment_name=deployment_name)

        kv_output_parameters = self._data_store.get_contents(
            content_type=ContentType.TEXT,
            container_name=self._vdc_storage_output_container_name,
            content_name=content_name)

        kv_output_parameters_json = json.loads(kv_output_parameters)
            
        for k, v in additional_output_parameters.items():
            kv_output_parameters_json[k] = {'value': v}
        
        output_data = json.dumps(kv_output_parameters_json)

        # Update blob storage
        self._data_store.store_contents(
            content_type=ContentType.TEXT,
            container_name=self._vdc_storage_output_container_name,
            content_name=content_name,
            content_data=helper.cleanse_output_parameters(output_data))

    def certificate_information_extraction(
        self,
        kv_name: str,
        certificate_name: str):

        '''Function to obtain a stored certificate key vault instance.
        This function obtains the details of a certificate from a given key vault.

        :param kv_name: The name of the key vault.
        :type kv_name: str
        :param certificate_name: The name of the certificate used for extracting data.
        :type certificate_name: str

        :return: The full url of the certificate within key vault (certificate_url) 
        and the thumbnail of the certificate (certificate_thumb)
        :rtype: str, str
        :raises: :class:`Exception`
        '''
        self._logger.debug('Obtaining certificate {} from the {} key vault.'.format(
            certificate_name, kv_name))

        try:

            # Extracting the certificate from key vault.
            #-----------------------------------------------------------------------------

            json_certificate_output = self._keyvault_cli_integration_service.get_kv_certificate(
                kv_name=kv_name,
                cert_name=certificate_name)
            
            self._logger.debug('The extract certificate command executed successfuly, producing the following output: {}'
                        .format(json_certificate_output))

            # Check if the command returned a key definition.
            if len(json_certificate_output) <= 0:
                raise ValueError('The certificate output does not contain a module definition.')
            
            certificate_url = json_certificate_output['sid']
            certificate_thumb = json_certificate_output['x509ThumbprintHex']

            return certificate_url, certificate_thumb

        except ValueError as e:
            
            self._logger.error('It was not possible to obtain the {} certificate.'.format(
                certificate_name))
            self._logger.error('The following error occurred: ' + str(e))
            raise(e)
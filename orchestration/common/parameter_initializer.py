from orchestration.data.blob_storage import BlobStorage
from orchestration.models.integration_type import IntegrationType
from orchestration.models.sdk_type import SdkType
from orchestration.common.factory import ObjectFactory
from orchestration.models.storage_type import StorageType
from orchestration.common import helper
import logging
import json

class ParameterInitializer(object):

    _logger = logging.getLogger(__name__)
    _json_parameters: dict = None

    def initialize(
        self, 
        args: dict,
        deployment_configuration_path: str,
        is_live_mode: bool):
        """Function initializes all required parameters used during resource
        deployment, resource validation and policy creation & assignment.

        :param args: Arguments received from command line
        :type args: dict
        :param deployment_configuration_path: Local path to the main parameters file (deployment configuration file)
        :type deployment_configuration_path: str
        :param is_live_mode: Boolean that is set to False when running integration tests in playback mode.
        Playback mode uses VCR.py to simulate HTTP interactions
        :type is_live_mode: bool
        """

        self._logger.info('initializing parameters')

        # Setting defaults in case values are not passed
        self._vdc_storage_account_name = "vdcstrgaccount"
        self._vdc_storage_account_resource_group = "vdc-storage-rg"
        self._parameters_file_name = 'azureDeploy.parameters.json'
        self._deployment_file_name = 'azureDeploy.json'
        self._service_principals = list()
        self._deploy_all_modules = True
        self._deploy_module_dependencies = False
        self._deployment_configuration_path = deployment_configuration_path
        self._upload_scripts = False
        self._service_principals = None
        self._module_dependencies = None
        self._encryption_keys_for = None
        self._shared_services_subscription_id = ''
        self._vdc_storage_account_subscription_id = ''
        self._validate_deployment = False
        self._delete_validation_modules = False
        self._import_module = ''
        self._custom_scripts_path = ''

        # Let's set validate deployment boolean
        if 'validate-deployment' in args:
            self._validate_deployment = args['validate-deployment']
        
        # Let's analyze if a single module will be deployed
        if args['module'] != None:
            self._deploy_all_modules = False

        # Let's get deployment parameters
        self._resource_group = args['resource-group']
        self._environment_type = args['environment-type']
        self._single_module = args['module']
        self._client_id = None
        self._secret = None
        self._tenant_id = None
        self._create_vdc_storage = True

        if 'client-id' in args:
            self._client_id = args['client-id']

        if 'secret' in args:
            self._secret = args['secret']

        if 'tenant-id' in args:
            self._tenant_id = args['tenant-id']

        self._subscription_id = ''

        if 'subscription-id' in args:
            self._subscription_id = args['subscription-id']
        
        self._deploy_module_dependencies = args['deploy-module-dependencies']
        self._upload_scripts = args['upload-scripts']
        self._create_vdc_storage = args['create-vdc-storage']
        self._delete_validation_modules = False

        if 'delete-validation-modules' in args:
            self._delete_validation_modules = \
                args['delete-validation-modules']
        
        # If is_live_mode is False, it means we are in playback mode, therefore use
        # test parameters file
        if not is_live_mode:
            self._parameters_file_name = 'archetype.test.json'

        # Let's analyze the parameters file
        # Parameters file overrides any argument passed
        if self._json_parameters is None:
            self._json_parameters = \
                self._get_json_configuration_file(deployment_configuration_path)
        
        if self._subscription_id == '' and\
           self._environment_type in self._json_parameters['general'] and\
           'subscription-id' in self._json_parameters['general'][self._environment_type]:
            self._subscription_id = \
                self._json_parameters['general'][self._environment_type]['subscription-id']
        
        self.validate_required_parameters(
            self._environment_type, 
            deployment_configuration_path)

        self._location = \
            self._json_parameters['general'][self._environment_type]['region']   
        
        if self._tenant_id == None:
            self._tenant_id = self._json_parameters['general']['tenant-id']
        
        self._organization_name = \
            self._json_parameters['general']['organization-name']
        self._deployment_name = \
            self._json_parameters['general'][self._environment_type]['deployment-name']
        self._module_deployment_order = \
            self._json_parameters['orchestration']['modules-to-deploy']                
        self._shared_services_deployment_name = \
            self._json_parameters['shared-services']['deployment-name']

        if  'shared-services' in self._json_parameters['general'] and \
            'subscription-id' in self._json_parameters['general']['shared-services']:
            self._shared_services_subscription_id = \
                self._json_parameters['general']['shared-services']['subscription-id']
        
        # Use the shared_services subscription id, this is where VDC storage gets created
        if  'shared-services' in self._json_parameters['general'] and \
            'subscription-id' in self._json_parameters['general']['shared-services']:
            self._vdc_storage_account_subscription_id = \
                self._json_parameters['general']['shared-services']['subscription-id']
        
        if 'vdc-storage-account-name' in self._json_parameters['general'] \
            and self._json_parameters['general']['vdc-storage-account-name'] is not None:
            self._vdc_storage_account_name = \
                self._json_parameters['general']['vdc-storage-account-name']

        if 'vdc-storage-account-rg' in self._json_parameters['general'] \
            and self._json_parameters['general']['vdc-storage-account-rg'] is not None:
            self._vdc_storage_account_resource_group = \
                self._json_parameters['general']['vdc-storage-account-rg']

        # Now that all the necessary parameters are initialized, let's initialize integration objects
        self._initialize_integration_objects(is_live_mode)

        self._environment_keys = dict({
            'ENV:ENVIRONMENT-TYPE': self._environment_type,
            'ENV:RESOURCE-GROUP-NAME': self._resource_group,
            'ENV:RESOURCE': self._single_module
        })

        self._json_parameters = \
            self._replace_parameters_tokens(
                dict_with_tokens=self._json_parameters,
                parameters=self._json_parameters,
                environment_keys=self._environment_keys)

        if 'service-principals' in self._json_parameters[self._environment_type] \
            and self._json_parameters[self._environment_type]['service-principals'] is not None:
            self._service_principals = self._json_parameters[self._environment_type]['service-principals'].split(',')
        else:
            self._service_principals = args['service-principals']

        if 'orchestration' in self._json_parameters and\
           'module-configuration' in self._json_parameters['orchestration'] and\
           'modules' in self._json_parameters['orchestration']['module-configuration']:
            self._module_dependencies = self._json_parameters['orchestration']['module-configuration']['modules']

        if 'orchestration' in self._json_parameters and\
           'module-configuration' in self._json_parameters['orchestration'] and\
           'import-modules' in self._json_parameters['orchestration']['module-configuration']:
            self._import_module = self._json_parameters['orchestration']['module-configuration']['import-modules']
        
        if 'orchestration' in self._json_parameters and\
           'module-configuration' in self._json_parameters['orchestration'] and\
           'custom-scripts' in self._json_parameters['orchestration']['module-configuration']:
            self._custom_scripts_path = self._json_parameters['orchestration']['module-configuration']['custom-scripts']
        
        if  'vm-configuration' in self._json_parameters[self._environment_type] and\
            'encryption-keys-for' in self._json_parameters[self._environment_type]['vm-configuration']:
            self._encryption_keys_for = self._json_parameters[self._environment_type]['vm-configuration']['encryption-keys-for']

        object_factory = ObjectFactory(is_live_mode)

        self._module_version_retrieval = \
            object_factory.get_module_version_retrieval(self._import_module)
        
        self._logger.info("Parameter initialization, complete")

    def _replace_parameters_tokens(
        self,
        dict_with_tokens: dict,
        parameters: dict,
        environment_keys: dict):
        """Function that replaces tokens from the main configuration file (main parameters file)

        :param dict_with_tokens: JSON object representing main configuration file
        :type dict_with_tokens: dict
        :param parameters: Object containing values used to replace tokens from dict_with_tokens
        :type parameters: dict
        :param environment_keys: Environment keys containing values passed from the command line
        :type environment_keys: dict
        """

        import copy
        # Let's update the parameters file tokens, if any
        # Keep updating until all tokens have been replaced.
        # The loop is required because there are tokens that 
        # references other values that happen to be tokens
        while helper.has_token(parameters):
            parameters = \
                helper.replace_all_tokens(
                    dict_with_tokens=copy.deepcopy(dict_with_tokens),
                    parameters=parameters,
                    organization_name=self._organization_name,
                    shared_services_deployment_name=self._shared_services_deployment_name,
                    workload_deployment_name=self._deployment_name,
                    storage_container_name='output',
                    storage_access=self._data_store,
                    validation_mode=self._validate_deployment,
                    environment_keys=environment_keys)
        
        # Let's execute operations, if any
        replaced_string = helper.operations(
            json.dumps(parameters), 
            parameters)

        parameters = \
            json.loads(replaced_string)

        return parameters

    def _initialize_integration_objects(
        self,
        is_recording: bool):
        """Function that initializes integration objects used during a resource deployment

        :param is_recording: Value set to True when running integration tests recording (using VCR.py)
        all HTTP interactions 
        :type is_recording: bool
        """
        object_factory = ObjectFactory(is_recording)

        self._data_store = \
            object_factory.storage_factory(
                    StorageType.BLOB_STORAGE,
                    client_id=self._client_id,
                    secret=self._secret,
                    tenant_id=self._tenant_id,
                    location=self._location,
                    subscription_id=self._vdc_storage_account_subscription_id,
                    storage_account_name=self._vdc_storage_account_name,
                    storage_account_resource_group=self._vdc_storage_account_resource_group)
                    
        self._resource_management_integration_service = \
            object_factory.integration_factory(
                IntegrationType.RESOURCE_MANAGEMENT_CLIENT_SDK,
                client_id=self._client_id, 
                secret=self._secret, 
                tenant_id=self._tenant_id,
                subscription_id=self._subscription_id)

        self._policy_integration_service = \
            object_factory.integration_factory(
                IntegrationType.POLICY_CLIENT_SDK,
                client_id=self._client_id, 
                secret=self._secret, 
                tenant_id=self._tenant_id,
                subscription_id=self._subscription_id)

        self._management_lock_integration_service = \
            object_factory.integration_factory(
                IntegrationType.MANAGEMENT_LOCK_CLIENT_SDK,
                client_id=self._client_id, 
                secret=self._secret, 
                tenant_id=self._tenant_id,
                subscription_id=self._subscription_id)

        self._aad_cli_integration_service = \
            object_factory.integration_factory(
                IntegrationType.AAD_CLIENT_CLI)

        self._keyvault_cli_integration_service = \
            object_factory.integration_factory(
                IntegrationType.KEYVAULT_CLIENT_CLI)

    def _get_json_configuration_file(
        self,
        deployment_configuration_path: str):
        """Function reads a local path that contains deployment configuration settings

        :param deployment_configuration_path: Deployment configuration file path
        :type deployment_configuration_path: str
        """
        from orchestration.common.local_file_finder import LocalFileFinder
        from orchestration.common.remote_file_finder import RemoteFileFinder

        local_file_finder = LocalFileFinder()
        remote_file_finder = RemoteFileFinder()

        if local_file_finder.can_parse_path(deployment_configuration_path):
            return \
                local_file_finder.read_file(
                    deployment_configuration_path)
        else:
            return \
                remote_file_finder.read_file(
                    deployment_configuration_path)
    
    def validate_required_parameters(
        self, 
        environment_type: str,
        deployment_configuration_path: str):
        """Function that validates that the required parameters contains values

        :param environment_type: Allowed values are: Shared-Services, Workload or On-premises
        :type environment_type: str
        :param deployment_configuration_path: Deployment configuration file path
        :type deployment_configuration_path: str
        """

        if self._json_parameters == None:
            self._json_parameters = \
                self._get_json_configuration_file(deployment_configuration_path)

        if 'general' not in self._json_parameters:
            raise ValueError('general property missing in parameters file')

        if 'shared-services' not in self._json_parameters['general']:
            raise ValueError('shared-services property missing in general object')


        if 'organization-name' not in self._json_parameters['general']:
            raise ValueError('organization-name missing in general property')
        
        if 'orchestration' not in self._json_parameters:
            raise ValueError('orchestration property missing')
        
        if 'module-configuration' not in self._json_parameters['orchestration']:
            raise ValueError('module-configuration property missing in orchestration object')
        
        if 'import-modules' not in self._json_parameters['orchestration']['module-configuration']:
            raise ValueError('import-modules property missing in module-configuration object')

        if 'custom-scripts' not in self._json_parameters['orchestration']['module-configuration']:
            raise ValueError('custom-scripts property missing in module-configuration object')

        if 'modules' not in self._json_parameters['orchestration']['module-configuration']:
            raise ValueError('modules property missing in module-configuration object')
        
        if 'modules-to-deploy' not in self._json_parameters['orchestration']:
            raise ValueError('modules-to-deploy missing in orchestration object')

        # Let's analyze if shared_services or workload parameters exist
        if environment_type not in self._json_parameters:
            raise ValueError("{} being deployed, {} property must exist".format(
                environment_type,
                environment_type
            ))
        
        # Let's analyze the location
        if 'region' not in self._json_parameters[environment_type]:  
            raise ValueError('No region has been set')

        # Let's analyze the subscription id 
        if  self._subscription_id == '' or \
            'subscription-id' not in self._json_parameters['general']['shared-services']:            
            raise ValueError('No subscription id has been set')

        if 'deployment-name' not in self._json_parameters[environment_type]:
                raise ValueError("deployment-name property missing in {} property".format(
                    environment_type))

        # If a workload is being deployed, shared_services property should exist
        if environment_type == 'workload':
            if 'shared-services' not in self._json_parameters:
                raise ValueError("workload is being deployed, shared_services property must exist")

            # Now, let's get the shared_services deployment name    
            if 'deployment-name' not in self._json_parameters['shared-services']:
                raise ValueError("deployment-name property missing in shared_services property")
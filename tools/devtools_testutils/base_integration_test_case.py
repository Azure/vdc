from tools.devtools_testutils.base_replayable_test_case import (
    VDCBaseTestCase)

class BaseIntegrationTestCase(VDCBaseTestCase):
    
    def setUp(self):
        super(BaseIntegrationTestCase, self).setUp()
    
    def set_resource_to_deploy(
        self,
        resource: str,
        args: dict):
        args['module'] = resource

    def upload_scripts(
        self,
        args: dict,
        upload: bool):
        
        args['upload-scripts'] = upload

    def create_vdc_storage(
        self,
        args: dict,
        create: bool):
        
        args['create-vdc-storage'] = create

    def execute_deployment_test(
        self,
        args: dict,
        configuration_path: str,
        environment_type: str) -> bool:
        
        from orchestration.common.factory import ObjectFactory
        from orchestration.common.parameter_initializer import ParameterInitializer

        factory = ObjectFactory(is_live_mode=self.is_live)

        parameter_initializer = \
                factory.get_parameter_initializer()
        parameter_initializer.initialize(
            args, 
            configuration_path,
            is_live_mode=self.is_live)
        
        from orchestration.resource_deployment import ResourceDeployment
        resourceDeployment = ResourceDeployment(
            parameter_initializer._data_store, 
            parameter_initializer._resource_management_integration_service,
            parameter_initializer._policy_integration_service,  
            parameter_initializer._aad_cli_integration_service,
            parameter_initializer._keyvault_cli_integration_service,
            parameter_initializer._module_version_retrieval,
            parameter_initializer._vdc_storage_account_name,
            parameter_initializer._vdc_storage_account_subscription_id,
            parameter_initializer._vdc_storage_account_resource_group,
            parameter_initializer._validate_deployment,
            parameter_initializer._deploy_all_modules,
            parameter_initializer._deployment_configuration_path,
            parameter_initializer._module_deployment_order,
            parameter_initializer._resource_group,
            parameter_initializer._single_module,
            parameter_initializer._deploy_module_dependencies,
            parameter_initializer._upload_scripts,
            parameter_initializer._create_vdc_storage,
            parameter_initializer._shared_services_deployment_name,
            parameter_initializer._deployment_name,
            parameter_initializer._location,
            parameter_initializer._tenant_id,
            parameter_initializer._subscription_id,
            parameter_initializer._shared_services_subscription_id,
            parameter_initializer._service_principals,
            parameter_initializer._organization_name,
            parameter_initializer._encryption_keys_for,
            parameter_initializer._module_dependencies,
            parameter_initializer._environment_type,
            parameter_initializer._json_parameters,
            parameter_initializer._import_module,
            parameter_initializer._custom_scripts_path,
            parameter_initializer._environment_keys,
            from_integration_test=True)
        
        # Invoke deployment
        successful: list = resourceDeployment.create()

        return len(successful) > 0
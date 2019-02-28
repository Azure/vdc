from pathlib import Path
from sys import argv
from argparse import ArgumentParser, FileType
from logging.config import dictConfig
import logging
import json

# Logging preperation.
#-----------------------------------------------------------------------------

# Set the log configuration using a json config file.        
if Path('logging/config.json').exists():
    with open('logging/config.json', 'rt') as f:
        config = json.load(f)
        dictConfig(config)
else:
    logging.basicConfig(level=logging.INFO)

# Create a new logger instance using the provided configuration.
_logger = logging.getLogger(__name__)

def create_deployment(parsed_args):
    
    # Gather the provided argument within an array.
    args = vars(parsed_args)
    
    # Capture the parameters provided for debugging.
    _logger.debug('The parameters extracted were: {}'.format(args))
    
    configuration_path = args['configuration-path']
    
    # Setting deployment-type -> shared-services | workload | on-premises
    environment = args['environment-type']
    
    _logger.info('Provisioning the following environment: {}'.format(environment))
    _logger.info('Deployment path is: {}'.format(configuration_path))
    
    #-----------------------------------------------------------------------------
    # Call the function indicated by the invocation command.
    #-----------------------------------------------------------------------------
    try:
        all_configuration_paths = list()

        all_configuration_paths = \
            configuration_path.split(',')

        _logger\
            .info('Configuration path(s): {}'\
                .format(all_configuration_paths))
        
        is_live_mode = True

        from orchestration.common.factory import ObjectFactory
        from orchestration.common.parameter_initializer import ParameterInitializer

        factory = ObjectFactory(is_live_mode=is_live_mode)

        for path in all_configuration_paths:
            
            parameter_initializer = \
                factory.get_parameter_initializer()
            parameter_initializer.initialize(
                args, 
                path,
                is_live_mode=is_live_mode)
            
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
                parameter_initializer._environment_keys)

            # Invoke deployment
            resourceDeployment.create()    
    except Exception as ex:
        _logger.error('There was an unhandled error while provisioning the resources.')
        _logger.error(ex)
        exit()

def validate_deployment(parsed_args):
    
    # Gather the provided argument within an array.
    args = vars(parsed_args)
    
    # Capture the parameters provided for debugging.
    _logger.debug('The parameters extracted were: {}'.format(args))
    
    configuration_path = args['configuration-path']
    
    # Setting deployment-type -> shared-services | workload | on-premises
    environment = args['environment-type']
    
    _logger.info('Validating templates of the following environment: {}'.format(environment))
    _logger.info('Deployment path is: {}'.format(configuration_path))
    
    #-----------------------------------------------------------------------------
    # Call the function indicated by the invocation command.
    #-----------------------------------------------------------------------------
    try:
        all_configuration_paths = list()

        all_configuration_paths = \
            configuration_path.split(',')

        _logger\
            .info('Configuration path(s): {}'.format(all_configuration_paths))
        
        is_live_mode = True
        args['validate-deployment'] = True
            
        from orchestration.common.factory import ObjectFactory
        from orchestration.common.parameter_initializer import ParameterInitializer

        factory = ObjectFactory(is_live_mode=is_live_mode)

        for path in all_configuration_paths:
            
            parameter_initializer = factory.get_parameter_initializer()
            parameter_initializer.initialize(
                args, 
                path,
                is_live_mode=is_live_mode)
            
            from orchestration.resource_validation import ResourceValidation
            resourceValidation = ResourceValidation(
                parameter_initializer._data_store, 
                parameter_initializer._management_lock_integration_service,
                parameter_initializer._resource_management_integration_service,
                parameter_initializer._policy_integration_service,  
                parameter_initializer._aad_cli_integration_service,
                parameter_initializer._keyvault_cli_integration_service,
                parameter_initializer._module_version_retrieval,
                parameter_initializer._vdc_storage_account_name,
                parameter_initializer._vdc_storage_account_subscription_id,
                parameter_initializer._vdc_storage_account_resource_group,
                parameter_initializer._validate_deployment,
                parameter_initializer._delete_validation_modules,
                parameter_initializer._deploy_all_modules,
                parameter_initializer._module_deployment_order,
                'vdc-validation-test-rg', # Let's fix the validation resource group name
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
                parameter_initializer._environment_keys)
            
            # Invoke deployment validation
            resourceValidation.create()   
    except Exception as ex:
        _logger.error('There was an unhandled error while provisioning the resources.')
        _logger.error(ex)
        exit()

def set_create_arguments(parser):
        
    parser.add_argument('-rg', '--resource-group',
                dest='resource-group',
                required=False,
                help='Provisions a resource(s) in the resource group passed. Otherwise a default Organization-DeploymentType-ResourceType-rg resource group name will be created.')

    parser.add_argument('-m', '--module',
                dest='module',
                required=False,
                help='Specifies a module to provision, i.e. nsg, net, ops, kv, nva, jb, adds')

    parser.add_argument('-l', '--location',
                dest='location',
                required=False,
                help='Specifies the location to provision the resources')
    
    parser.add_argument('-path', '--configuration-file-path',
                dest='configuration-path',
                required=True,
                help='Specifies the main deployment path where the deployment templates, parameters and policies are')

    parser.add_argument('--deploy-dependencies',
                dest='deploy-module-dependencies',
                action="store_true",
                required=False,                
                help='Specifies whether or not resources dependencies are going to be provisioned. By default is set to False')

    parser.add_argument('-sp', '--service-principals',
                dest='service-principals',
                required=False,
                help='Comma separated string of Service Principal(s). Use this argument when deploying a KeyVault and your user(s) deploying the resources is/are Service Principal(s). The process will call "az keyvault set-policy --spn " to assign access policies to your KeyVault.')

    parser.add_argument('--upload-scripts',
                dest='upload-scripts',
                action="store_true",
                required=False,                
                help='Specifies whether or not the scripts folder gets uploaded to the default storage account. By default is set to False')

    parser.add_argument('environment-type', 
                choices=['shared-services', 'workload', 'on-premises'])
    
    parser.add_argument('--prevent-vdc-storage-creation',
                dest='create-vdc-storage',
                action="store_false",
                required=False,                
                help='Specifies whether or not to create a new storage account. By default is set to True')

def set_validation_arguments(parser):
    set_create_arguments(parser)

    parser.add_argument('--delete-validation-modules',
                dest='delete-validation-modules',
                action="store_true",
                required=False,                
                help='Specifies whether or not to delete all resources provisioned during the validation process. By default is set to False')


def main():
    
    #-----------------------------------------------------------------------------
    # Script argument definitions.
    #-----------------------------------------------------------------------------

    # Define a top level parser.
    parser = ArgumentParser(
        description='Creates a brand new Azure Virtual DataCenter (VDC) through the creation of shared_services and workload environments.')
    
    # Create a subparser to distinguish between the different deployment commands.
    subparsers = parser.add_subparsers(
        help='Creates the respective Azure Virtual DataCenter environment.')

    create_subparser = subparsers\
        .add_parser(
            'create', 
            help='Creates a brand new Shared Services, Workload or On-premises environment according to specified parameters.')

    set_create_arguments(create_subparser)

    create_subparser\
        .set_defaults(
            func=create_deployment)

    validate_subparser = subparsers\
        .add_parser(
            'validate', 
            help='Validates if Shared Services, Workload or On-premises templates are syntactically correct.')

    set_validation_arguments(validate_subparser)

    validate_subparser\
        .set_defaults(
            func=validate_deployment)
    
    #-----------------------------------------------------------------------------
    # Process parameter arguments.
    #-----------------------------------------------------------------------------

    args = parser.parse_args()
    
    # Let's check if there are parameters passed, if not, print function usage
    if len(vars(args)) == 0:
        parser.print_usage()
        exit()
    
    args.func(args)
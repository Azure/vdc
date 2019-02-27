from pathlib import Path
from sys import argv
from argparse import ArgumentParser, FileType
from logging.config import dictConfig
from orchestration.data.blob_storage import BlobStorage
from orchestration.common import helper
from exceptions.custom_exception import CustomException
from orchestration.common.factory import ObjectFactory
from orchestration.models.integration_type import IntegrationType
import logging
import json
import sys

sp_shell_flag: bool = False

if sys.platform == "linux" or sys.platform == "linux2":
    sp_shell_flag = False
elif sys.platform == "win32":
    sp_shell_flag = True
'''
boolean: A flag to capture if shell should be applied for sub process commands.
It must be set to true on Windows machines, but should be left as false when on Linux.
'''

# Logging preperation.
#-----------------------------------------------------------------------------

# Retrieve the main logger; picks up parent logger instance if invoked as a module.
_logger = logging.getLogger(__name__)
'''
_logger: Logger instance used to process all module log statements.
'''

def main():
    '''Main module used to assign policies provided within a json file.

    This module takes in a policy file containing a list of json arm policy definitions.
    In addition, this module takes in a subscription id and optional resource group name,
    which are used to produce an assignment scope for the application of policies.

    Examples:

    $ python policyassignment.py -p parameters/shared-services|workload/azureDeploy.parameters.json -pf ../policies/policies/sub.arm.policies.json -s <subscription_id>

    $ python policyassignment.py -p parameters/shared-services|workload/azureDeploy.parameters.json -pf ../policies/policies/kv.arm.policies.json -s <subscription_id> -r <resource_group_name>

    Args:
        policies: A json file containing a lisy of arm policies.
        subscription: The subscription id used for the assignment of policies.
        group: The optional resource group name used for the assignment of policies.
    '''

    # Logging configuration.
    #-----------------------------------------------------------------------------

    # Define some basic log configuration for if the script was called manually.
    logging.basicConfig(level=logging.INFO)

    # Parameter input.
    #-----------------------------------------------------------------------------

    # Define a parser to process the expected arguements.
    parser = ArgumentParser(
        description='Applies a set of ARM policies provided as a json file, at a given scope.')

    parser.add_argument('--configuration-file-path', 
                type=FileType('r'), 
                action='store',
                dest='configuration-path', 
                required=True,
                help='Path to json file containing environment configuration information, environment where the policies will be applied')

    parser.add_argument('-file', '--policy-file', 
                type=FileType('r'), 
                action='store',
                dest='policies', 
                required=True,
                help='Path to json file containing the policies to be applied.')
    
    parser.add_argument('--client-id',
                dest='client-id',
                action="store",
                type=str,
                required=False,                
                help='Specifies the ClientId. This value can be a SPN or AAD Object ID')

    parser.add_argument('--secret',
                dest='secret',
                action="store",
                type=str,
                required=False,                
                help="Specifies the ClientId's secret")

    parser.add_argument('--tenant-id',
                dest='tenant-id',
                action="store",
                type=str,
                required=False,                
                help='Specifies the TenantId')

    parser.add_argument('-sid', '--subscription-id',
                dest='subscription-id',
                required=False,
                help='Specifies the subscription identifier where the resources will be provisioned')

    parser.add_argument('-rg', '--resource-group', 
                type=str, 
                action='store', 
                dest='resource-group',
                required=False, 
                help='Resource group name used for policy assignment scope.')

    parser.add_argument('--management-group-id', 
                type=str, 
                action='store', 
                dest='management-group-id',
                required=False, 
                help='Management Group Id used for policy assignment scope.')

    # Gather the provided arguments as an array.
    args = parser.parse_args()

    # Script kickoff.
    #-----------------------------------------------------------------------------
    
    _logger.debug('The policy assignment script was invoked with the following parameters: {}'
                 .format(args))

    _logger.info('Policy assignment script will define and assign the provided policies.')

    # Variable assignment.
    #-----------------------------------------------------------------------------

    # Let's convert args into a dictionary
    args = vars(args)

    # Assign these arguments to variables.
    json_policies = json.load(args['policies'])
    # Close the policy file.
    args['policies'].close()

    # Assign these arguments to variables.
    json_configuration = json.load(args['configuration-path'])
    # Close the policy file.
    args['configuration-path'].close()

    if 'shared-services' not in json_configuration or 'subscription-id' not in json_configuration['shared-services'] or json_configuration['shared-services']['subscription-id'] == None:
        _logger.error('Missing or empty shared-services.subscription-id value. This value is used to indicate the subscription identifier of VDC storage account')
        exit()
    
    vdc_storage_account_subscription_id = json_configuration['shared-services']['subscription-id']
    vdc_storage_account_name = "vdcstrgaccount"
    vdc_storage_account_resource_group = "vdc-storage-rg"

    if 'vdc-storage-account-name' in json_configuration['general'] and json_configuration['general']['vdc-storage-account-name'] != None:
        vdc_storage_account_name = json_configuration['general']['vdc-storage-account-name']

    if 'vdc-storage-account-rg' in json_configuration['general'] and json_configuration['general']['vdc-storage-account-rg'] != None:
        vdc_storage_account_resource_group = json_configuration['general']['vdc-storage-account-rg']

    # Get the organization name    
    if 'organization-name' not in json_configuration['general']:
        _logger.error('Organization name has not been provided in the parameters file')
        exit()

    organization_name = \
        json_configuration['general']['organization-name']

    if 'deployment-name' not in json_configuration['shared-services']:
        _logger.error('Deployment name has not been provided in the parameters file')
        exit()

    shared_services_deployment_name = \
        json_configuration['shared-services']['deployment-name']
    
    # Set the initial value
    deployment_name = \
        json_configuration['shared-services']['deployment-name']
    
    # Set a default value
    location = "West US"

    # Let's get the shared-services region (if set). 
    # If we are deploying a workload, the next condition will grab the correct value
    if 'shared-services' in json_configuration and\
        'region' in json_configuration['shared-services']:
        location = json_configuration['shared-services']['region']     
    
    # If shared-services and workload parameters are present, it means we are deploying a workload,
    # otherwise shared-services parameter will only be present.
    if 'shared-services' in json_configuration and\
        'workload' in json_configuration:
        deployment_name = json_configuration['workload']['deployment-name']

        # Since we are in the workload, let's verify if region has been specified
        if 'region' in json_configuration['workload']:
            location = json_configuration['workload']['region']
       

    # Record the policies that were provided.
    _logger.debug('The following policies were provided: {}'
                .format(json_policies))

    if  args['subscription-id'] is None and\
        args['resource-group'] is None and\
        args['management-group-id'] is None:
        _logger.error('Subscription Id or Management Group Id must contain a value')
        exit()

    if  args['resource-group'] is not None and\
        args['subscription-id'] is None:
        _logger.error('Subscription Id must be specified when assigning a policy at the resource group level')
        exit()

    assignment_scope = \
        '/subscriptions/{}'.format(args['subscription-id'])

    # Alter the policy scope if a resource group was provided.
    if args['management-group-id'] is not None:
        assignment_scope = \
            '/providers/Microsoft.Management/managementGroups/{}'\
                .format(args['management-group-id'])
    elif args['resource-group'] is not None:
        assignment_scope += \
            '/resourceGroups/{}'\
                .format(args['resource-group'])

        _logger.debug('The scope of policy assignments has been set to the {} resource group.'
                    .format(args['resource-group']))
    else:
        _logger.debug('The scope of policy assignments has been set to the {} subscription.'
                    .format(args['subscription-id']))
    
    # Policy invocation.
    #-----------------------------------------------------------------------------

    # Invoke the apply_policies function with the provided policies and scope.
    object_factory = ObjectFactory(is_live_mode=True)
    
    from orchestration.models.storage_type import StorageType
    data_store = object_factory.storage_factory(
        StorageType.BLOB_STORAGE,
        client_id=args['client-id'],
        secret=args['secret'],
        tenant_id=args['tenant-id'],
        location=location,
        subscription_id=vdc_storage_account_subscription_id,
        storage_account_name=vdc_storage_account_name,
        storage_account_resource_group=vdc_storage_account_resource_group)

    if args['subscription-id'] is None:
        sdk_integration_service = \
            object_factory\
            .integration_factory(
                IntegrationType.POLICY_CLIENT_SDK,
                client_id=args['client-id'],
                secret=args['secret'],
                tenant_id=args['tenant-id'])
    else:
        sdk_integration_service = \
            object_factory\
            .integration_factory(
                IntegrationType.POLICY_CLIENT_SDK,
                client_id=args['client-id'],
                secret=args['secret'],
                tenant_id=args['tenant-id'],
                subscription_id=args['subscription-id'])
    
    # Replace tokens, if any    
    replaced_policies = helper.replace_string_tokens(
                json.dumps(json_policies['policies']),
                json_configuration,
                organization_name,
                shared_services_deployment_name,
                deployment_name,
                'output',
                data_store)
    
    sdk_integration_service.create_and_assign_policy(
        scope=assignment_scope,
        policies=json.loads(replaced_policies),
        deployment_parameters=json_configuration)

    # Results.
    #-----------------------------------------------------------------------------

    # The main module has finished executing, so reflect this.
    _logger.info('-------------------------------------------------------------------------')
    _logger.info('Policy assignment script has finished executing.')
    _logger.info('-------------------------------------------------------------------------')
from pathlib import Path
from sys import argv
from argparse import ArgumentParser, FileType
from orchestration.common import helper
from logging.config import dictConfig
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
logger = logging.getLogger(__name__)
'''
logger: Logger instance used to process all module log statements.
'''

def main():
    '''Main module used to create add roles provided within a json file.

    This module takes in a role file containing a list of json aad role definitions.

    Examples:

    $ python rolecreation.py -sid "00000000-0000-0000-0000-000000000000" -r ../parameters/roles/shared-services/aad.roles.json 

    Args:
        roles: A json file containing a list of aad roles.
    '''

    #Logging configuration.
    #-----------------------------------------------------------------------------

    # Define some basic log configuration for if the script was called manually.
    logging.basicConfig(level=logging.DEBUG)

    # Parameter input.
    #-----------------------------------------------------------------------------

    # Define a parser to process the expected arguments.
    parser = ArgumentParser(
        description='Creates AAD role definitions which are provided within a json file.')

    parser.add_argument('-sid', '--subscription-id',
                dest='subscription-id',
                required=True,
                help='Specifies the subscription identifier where the resources will be provisioned')

    parser.add_argument('-r', metavar='--roles-file', type=FileType('r'), action='store',
                        dest='roles', required=True,
                        help='Path to json file containing role definitions to be established.')

    # Gather the provided arguments as an array.
    args = parser.parse_args()

    # Script kickoff.
    #----------------------------------------------------------------------------- 

    logger.debug('The aad role creation script was invoked with the following parameters: {}'
                 .format(args))

    logger.info('Thus script will establish the provided AAD role definitions.')
    
    # Variable assignment.
    #-----------------------------------------------------------------------------

    # Assign these arguments to variables.
    json_roles = json.load(args.roles)
    # Close the policy file.
    args.roles.close()

    values = dict()
    values['subscription-id'] = vars(args)['subscription-id']

    # Let's replace the values passed as arguments
    replaced_parameters = helper.replace_string_tokens(
            json.dumps(json_roles), 
            values,
            None,
            None,
            None,
            None,
            None)

    # Role definition creation.
    #-----------------------------------------------------------------------------

    # Invoke the create_role function with the provided role definition file.
    object_factory = ObjectFactory(is_live_mode=False)
    cli_integration_service = object_factory.integration_factory(
                    IntegrationType.RBAC_CLIENT_CLI) 

    # TODO: For now, passing None as Client & Secret Id, Subs Id and Tenant Id
    cli_integration_service.create_RBAC(
        client_id=None,
        secret=None,
        tenant_id=None,
        subscription_id=None,
        roles=json.loads(replaced_parameters))
    
    # Results
    #-----------------------------------------------------------------------------

    # The main script has finished executing, so reflect this.
    logger.info('-------------------------------------------------------------------------')
    logger.info('AAD role creation script has finished executing.')
    logger.info('-------------------------------------------------------------------------')
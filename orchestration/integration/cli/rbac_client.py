import subprocess as sp
import json
import logging
import sys

class RBACClientCli(object):
    
    _sp_shell_flag: bool = False

    # Logging preperation.
    #-----------------------------------------------------------------------------

    # Retrieve the main logger; picks up parent logger instance if invoked as a module.
    _logger = logging.getLogger(__name__)
    '''
    logger: Logger instance used to process all module log statements.
    '''

    def __init__(self):
        
        if sys.platform == "linux" or sys.platform == "linux2":
            self._sp_shell_flag = False
        elif sys.platform == "win32":
            self._sp_shell_flag = True

    def create_RBAC(
        self,
        client_id: str, 
        secret: str, 
        tenant_id: str, 
        subscription_id: str,
        roles: dict):
        """Function creates RBAC by reading a file located in roles/aad.roles.json

        :param client_id: Client ID
        :type client_id: str
        :param secret: Client Secret
        :type secret: str
        :param tenant_id: Tenant ID
        :type tenant_id: str
        :param subscription_id: Subscription ID
        :type subscription_id: str
        :param roles: Roles (json deserialized) object
        :type roles: dict
        
        :raises: :class:`Exception`
        """
        sp_shell_flag: bool = False

        if sys.platform == "linux" or sys.platform == "linux2":
            sp_shell_flag = False
        elif sys.platform == "win32":
            sp_shell_flag = True

        # Loop through all of the given roles, creating and invoking the definition
        # command as a separate process.
        for role in roles:

            # Check if role already exists.
            #-----------------------------------------------------------------------------

            try:

                role_check_command = [
                    'az',
                    'role',
                    'definition',
                    'list',
                    '--name', role['Name']
                ]

                self._logger.debug('The role check command to execute is: {}'.format(role_check_command))

                # Check if the role exists to determine if the create or update command should be performed.
                check_output = sp.check_output(role_check_command, shell=sp_shell_flag, universal_newlines=True)

                self._logger.debug('The role check command executed successfully, producing the following output: {}'
                            .format(check_output))

                # Convert the output to a json object.
                json_check_output = json.loads(check_output)

                
                # Check if the command returned a role definition, indicating it already exists.
                if len(json_check_output) > 0:

                    self._logger.info('The {} role already exists and will be updated with the provided values.'
                                .format(role['Name']))

                    try:

                        # Update existing role.
                        #-----------------------------------------------------------------------------

                        # Update the role definition with the logical name of the role.
                        role['Name'] = json_check_output[0]['name']

                        # Establish the update role command, using the role definition.
                        role_update_command = [
                            'az',
                            'role',
                            'definition',
                            'update',
                            '--role-definition', json.dumps(role)
                        ]

                        self._logger.debug('The role update command to execute is: {}'
                                    .format(role_update_command))

                        # Update the role.
                        sp.check_call(role_update_command, shell=sp_shell_flag, universal_newlines=True)
                        
                        self._logger.info('The {} role was updated successfully.'.format(role['Name']))

                    except sp.CalledProcessError as e:

                        self._logger.error('The role update command failed.')
                        self._logger.error('The following error occurred: ' + str(e))

                # If the role does not already exist.
                else:

                    self._logger.info('The {} role does not exist or cannot be retrieved, so a new definition will be created.'
                                .format(role['Name']))
                    
                    try:

                        # Create a new role.
                        #-----------------------------------------------------------------------------

                        # Establish the role definition command, using the json role definition.
                        role_definition_command = [
                            'az',
                            'role',
                            'definition',
                            'create',
                            '--role-definition', json.dumps(role)
                        ]

                        self._logger.debug('The role definition command to execute is: {}'
                                .format(role_definition_command))

                        # Create a new role definition.
                        sp.check_call(role_definition_command, shell=sp_shell_flag, universal_newlines=True)
                    
                        # NOTE: The check command will not return a role definition if it is not within the scope of the 
                        # utilised subscription. The definition command will be invoked as this script cannot ascertain
                        # its existance. However, this command will fail as the role definition does technically exist,
                        # just not within the scope of this subscription.

                        self._logger.info('The {} role was created successfully.'.format(role['Name']))

                    except sp.CalledProcessError as e:

                        self._logger.error('The role create command failed.')
                        self._logger.error('The following error occurred: ' + str(e))
                        sys.exit(1)

            except sp.CalledProcessError as e:

                self._logger.error('The role check command failed.')
                self._logger.error('The following error occurred: ' + str(e))
                sys.exit(1)
import subprocess as sp
import json
import logging
import sys

class ResourceManagementClientCli(object):
    
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

    def resource_exists(self, resource_id: str):
        """Function that verifies if a resource exists based on its id

        :param resource_id: Resource ID
        :type resource_id: str
        """
        sp_shell_flag: bool = False

        if sys.platform == "linux" or sys.platform == "linux2":
            sp_shell_flag = False
        elif sys.platform == "win32":
            sp_shell_flag = True
        try:
            resource_show_command = [
                    'az',
                    'resource',
                    'show',
                    '--ids', resource_id
                ]

            self._logger.debug('The command to execute is: {}'.format(resource_show_command))

            # Check if the role exists to determine if the create or update command should be performed.
            check_output = sp.check_output(resource_show_command, shell=sp_shell_flag, universal_newlines=True)

            self._logger.debug('The command executed successfuly, producing the following output: {}'
                        .format(check_output))
            
            # Convert the output to a json object.
            json_check_output = json.loads(check_output)

            
            # Check if the command returned a values, indicating it already exists.
            if len(json_check_output) > 0:
                return True
            else:
                return False

        except sp.CalledProcessError as e:

                self._logger.error('The role check command failed.')
                self._logger.error('The following error occurred: ' + str(e))
                sys.exit(1)
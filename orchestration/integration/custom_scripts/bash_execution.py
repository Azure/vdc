import subprocess as sp
import json
import logging
import sys

class BashScriptExecution(object):

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

    def execute(
        self, 
        command: str) -> dict:
        try:
            self._logger.debug('Executing the following command: {}.'
                    .format(command))
            bash_command = "sh -c \"{}\"".format(command)
            # Package that splits based on whitespace and
            # preserves quoted strings
            import shlex
            command_exec = shlex.split(bash_command)

            # Run the check command.
            result = sp.check_output(command_exec, shell=self._sp_shell_flag, universal_newlines=True)
            
            self._logger.debug('The command executed successfuly, producing the following output: {}'
                        .format(result))

            try:
                result = json.loads(result)
            except:
                result = \
                        result\
                            .replace('\n', '')\
                            .replace('\\n', '')
            
            result_dict = dict({
                'output': result
            })

            return result_dict

        except sp.CalledProcessError as e:

            self._logger.error('The following error occurred: ' + str(e))
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
        except ValueError as e:

            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
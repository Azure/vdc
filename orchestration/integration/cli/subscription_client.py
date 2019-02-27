import subprocess as sp
import json
import logging
import sys

class SubscriptionClientCli(object):
    
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

    def set_subscription(
        self,
        subscription_id: str):
        """Function that sets a subscription

        :param subscription_id: Subscription ID
        :type subscription_id: str

        :raises: :class:`Exception`
        """

        try:
            self._logger.debug('Creating a new encryption key.')

            # Create encryption key.
            #-----------------------------------------------------------------------------
            
            set_subs_command = [
                'az',
                'account',
                'set',
                '--subscription', subscription_id
            ]

            sp.check_output(set_subs_command, shell=self._sp_shell_flag, universal_newlines=True)
        except sp.CalledProcessError as e:

            self._logger.error('The following error occurred: ' + str(e))
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
        except ValueError as e:
            
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
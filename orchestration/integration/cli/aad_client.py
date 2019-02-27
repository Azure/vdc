import subprocess as sp
import json
import logging
import sys

class AADClientCli(object):

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

    def get_aad_sp(
        self, 
        service_principal_name: str):
        """Function that retrieves a service principal

        :param service_principal_name: Service principal name
        :type service_principal_name: str
        
        :return: Service principal (deserialized) object
        :rtype: dict
        :raises: :class:`Exception`
        """

        try:
            self._logger.debug('Getting an aad principle with the name {}.'
                    .format(service_principal_name))

            add_app_check_command = [
                    'az',
                    'ad',
                    'sp',
                    'list',
                    '--display-name', service_principal_name,
            ]

            # Run the check command.
            aad_app = sp.check_output(add_app_check_command, shell=self._sp_shell_flag, universal_newlines=True)

            self._logger.debug('The aad application check command executed successfuly, producing the following output: {}'
                        .format(aad_app))

            # Convert the output to json.
            return json.loads(aad_app)
        except sp.CalledProcessError as e:

            self._logger.error('It was not possible to retrieve a service principal.')
            self._logger.error('The following error occurred: ' + str(e))
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
        except ValueError as e:
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)

    def create_aad_sp(
        self, 
        service_principal_name: str, 
        kv_name: str, 
        cert_name: str):
        """Function that creates a service principal and associates it (access policy) to a KeyVault instance

        :param service_principal_name: Service principal name
        :type service_principal_name: str
        :param kv_name: KeyVault name
        :type kv_name: str
        :param cert_name: Certificate name (must exist in KeyVault - kv_name)
        :type cert_name: str
        
        :return: Service principal (deserialized) object
        :rtype: dict
        :raises: :class:`Exception`
        """
        
        try:
            # Create a new aad application service principle.
            #-----------------------------------------------------------------------------

            self._logger.debug('The check command did not reveal an existing service principle with the name {}.'
                        .format(service_principal_name))

            self._logger.info('Creating a new aad application service principal.')

            aad_app_create_command = [
                        'az',
                        'ad',
                        'sp',
                        'create-for-rbac',
                        '--name', service_principal_name,
                        '--keyvault', kv_name,
                        '--cert', cert_name,
                        '--create-cert'
            ]

            # Run the aad sp check command.
            aad_app = sp.check_output(aad_app_create_command, shell=self._sp_shell_flag, universal_newlines=True)

            self._logger.debug('The aad application create command executed successfuly, producing the following output: {}'
                        .format(aad_app))

            # Convert the output to json.
            return json.loads(aad_app)
        except sp.CalledProcessError as e:

            self._logger.error('It was not possible to get create a service principal.')
            self._logger.error('The following error occurred: ' + str(e))
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
        except ValueError as e:
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)

    def reset_aad_sp_credentials(
        self, 
        service_principal_name: str,
        kv_name: str, 
        cert_name: str):
        """Function that resets service principal credentials

        :param service_principal_name: Service principal name
        :type service_principal_name: str
        :param kv_name: KeyVault name
        :type kv_name: str
        :param cert_name: Certificate name (must exist in KeyVault - kv_name)
        :type cert_name: str
        
        :return: Service principal (deserialized) object
        :rtype: dict
        :raises: :class:`Exception`
        """

        try:
            # Create a new certificate in case this is a new key vault instance.
            #-----------------------------------------------------------------------------

            self._logger.info('Resetting the certificate credentials for {}.'.format(service_principal_name))

            aad_reset_credentials_command = [
                'az',
                'ad',
                'sp',
                'credential',
                'reset',
                '--name', service_principal_name,
                '--keyvault', kv_name,
                '--cert', cert_name,
                '--create-cert'
            ]

            sp.check_call(aad_reset_credentials_command, shell=self._sp_shell_flag, universal_newlines=True)
        except sp.CalledProcessError as e:

            self._logger.error('It was not possible to reset the service principal credentials.')
            self._logger.error('The following error occurred: ' + str(e))
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
        except ValueError as e:
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
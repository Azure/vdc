import subprocess as sp
import json
import logging
import sys

class KeyVaultClientCli(object):

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

    def get_kv_certificate(
        self, 
        kv_name: str, 
        cert_name: str):
        """Function that retrieves a certificate stored in KeyVault

        :param kv_name: KeyVault name
        :type kv_name: str
        :param cert_name: Certificate name
        :type cert_name: str
        
        :return: certificate (json deserialized)
        :rtype: dict
        :raises: :class:`Exception`
        """

        try:
            certificate_extract_command = [
                'az',
                'keyvault',
                'certificate',
                'show',
                '--vault-name', kv_name,
                '--name', cert_name
            ]

            certificate_output = sp.check_output(certificate_extract_command, shell=self._sp_shell_flag, universal_newlines=True)

            self._logger.debug('The extract certificate command executed successfuly, producing the following output: {}'
                        .format(certificate_output))

            # Convert the output to a json object.
            return json.loads(certificate_output)
        except sp.CalledProcessError as e:

            self._logger.error('It was not possible to get a certificate from KeyVault.')
            self._logger.error('The following error occurred: ' + str(e))
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
        except ValueError as e:
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)

    def set_aad_sp_kv_access(
        self, 
        kv_name: str, 
        service_principal_id: str):
        """Function set access policy values to a KeyVault instance

        :param kv_name: KeyVault name
        :type kv_name: str
        :param service_principal_id: Service principal id
        :type service_principal_id: str
        
        :raises: :class:`Exception`
        """

        try:
            # Add Principal To Key Vault
            #-----------------------------------------------------------------------------

            self._logger.debug('Adding the established aad principle application to key vault.')

            kv_add_principal_command = [
                'az',
                'keyvault',
                'set-policy',
                '--name', kv_name,
                '--spn', service_principal_id,
                '--key-permissions', 'encrypt', 'decrypt', 'wrapKey', 'unwrapKey', 'sign',
                'verify', 'get', 'list', 'create', 'update', 'import', 'delete', 'backup',
                'restore', 'recover', 'purge',
                '--secret-permissions', 'get', 'list', 'set', 'delete', 'backup', 'restore',
                'recover', 'purge',
                '--certificate-permissions', 'get', 'list', 'delete', 'create', 'import',
                'update', 'managecontacts', 'getissuers', 'listissuers', 'setissuers',
                'deleteissuers', 'manageissuers', 'recover', 'purge'
            ]

            sp.check_call(kv_add_principal_command, shell=self._sp_shell_flag, universal_newlines=True)
        except sp.CalledProcessError as e:

            self._logger.error('It was not possible to get add a service principal to KeyVault.')
            self._logger.error('The following error occurred: ' + str(e))
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
        except ValueError as e:
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)

    def create_kv_encryption_keys(
        self, 
        key_name: str, 
        kv_name: str):
        """Function that creates encryption keys in KeyVault

        :param key_name: Encryption key name
        :type key_name: str
        :param kv_name: KeyVault name
        :type kv_name: str
        
        :return: Encryption Key ID
        :rtype: str
        :raises: :class:`Exception`
        """

        try:

            self._logger.debug('Creating a new encryption key.')

            # Create encryption key.
            #-----------------------------------------------------------------------------
            
            create_key_command = [
                'az',
                'keyvault',
                'key',
                'create',
                '--name', key_name,   
                '--protection', 'hsm',
                '--vault-name', kv_name,
                '--size', '2048'
            ]

            key_output = sp.check_output(create_key_command, shell=self._sp_shell_flag, universal_newlines=True)

            self._logger.debug('The create key command executed successfuly, producing the following output: {}'
                        .format(key_output))

            # Convert the output to a json object.
            json_key_output = json.loads(key_output)

            # Check if the command returned a key definition.
            if len(json_key_output) <= 0:
                raise ValueError('The key output does not contain a key definition.')
            
            key_id = json_key_output['key']['kid']

            return key_id
        
        except sp.CalledProcessError as e:

            self._logger.error('It was not possible to create the {} key.'.format(key_name))
            self._logger.error('The following error occurred: ' + str(e))
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
        except ValueError as e:
            
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
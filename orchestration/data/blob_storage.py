from azure.storage.blob import BlockBlobService, PublicAccess
from azure.storage.blob.models import Blob
from azure.storage.common.models import ResourceTypes, AccountPermissions
from azure.mgmt.storage.models import EncryptionService, EncryptionServices, Encryption, Sku, StorageAccountCreateParameters, StorageAccount, CheckNameAvailabilityResult, NetworkRuleSet
from azure.mgmt.storage import StorageManagementClient
from exceptions.custom_exception import CustomException
from orchestration.models.content_type import ContentType
from orchestration.common import helper as helper
from datetime import timedelta, date, datetime
from interface import implements
from orchestration.data.idata import DataInterface
from orchestration.integration.sdk.resource_management_client import ResourceManagementClientSdk
from pathlib import Path
import logging
class BlobStorage(implements(DataInterface)):

    _location: str = ''
    _logger = logging.getLogger(__name__)
    _vdc_storage_account_resource_group: str = None
    _vdc_storage_account_key: str = None
    _vdc_storage_account_name: str = None
    _resource_management_integration_service: ResourceManagementClientSdk
    _storage_management_client: StorageManagementClient

    def __init__(
        self,
        storage_management_client: StorageManagementClient,
        resource_management_integration_service: ResourceManagementClientSdk,
        location: str = None,
        storage_account_name: str = None,
        storage_account_resource_group: str = None):
        '''Class that interacts with Azure Storage Account.

        :param storage_management_client: Class in charge to interact with an Azure Storage Account          
        :type storage_management_client: StorageManagementClient
        :param resource_management_integration_service: Class required to create a resource group if one does not exists    
        :type resource_management_integration_service: ResourceManagementClientSdk
        :param location: (Optional) Parameter utilized in the creation of a resource group (if one does not exists) 
        and in the storage account creation. 
        If no value is passed, 'West US' is used as a default value.
        :type location: str
        :param storage_account_name: (Optional) Parameter utilized in the storage account creation.
        If no value is passed, 'vdcstorageaccount' is used as a default value.
        :type storage_account_name: str
        :param storage_account_resource_group: (Optional) Parameter utilized in the storage account creation.
        If no value is passed, 'vdc-storage-rg' is used as a default value.
        :type storage_account_resource_group: str
        '''

        self._storage_management_client = storage_management_client
        self._resource_management_integration_service = resource_management_integration_service

        # Setting defaults
        if location == None:
             self._location = "West US"
        else:
             self._location = location

        if storage_account_name == None:
            self._vdc_storage_account_name = "vdcstorageaccount"
        else:
            self._vdc_storage_account_name = storage_account_name

        if storage_account_name == None:
            self._vdc_storage_account_resource_group = "vdc-storage-rg"
        else:
            self._vdc_storage_account_resource_group = storage_account_resource_group

    def storage_exists(self):
        """Function that evaluates if the storage account name passed in the constructor, exists
        
        :return: exists
        :rtype: bool
        :raises: :class:`Exception`
        """

        name_availability: CheckNameAvailabilityResult
        name_availability = self._storage_management_client.storage_accounts.check_name_availability(
            self._vdc_storage_account_name)

        return name_availability

    def create_storage(self):
        """Function that creates a new storage account
        
        :raises: :class:`Exception`
        """

        if not self._resource_management_integration_service\
                   .resource_group_exists(
                    self._vdc_storage_account_resource_group):
            self._logger.info('No resource group: {} found, provisioning one.'.format(
                self._vdc_storage_account_resource_group))

            self._resource_management_integration_service\
                .create_or_update_resource_group(
                    self._vdc_storage_account_resource_group,
                    self._location)
        
        self._logger.info('Attempting authentication.')

        parameters: StorageAccountCreateParameters
        encryptionService = EncryptionService(enabled=True)
        encryptionServices = EncryptionServices(blob=encryptionService)
        encryption = Encryption(services=encryptionServices)
        
        parameters = StorageAccountCreateParameters(
            sku=Sku(name='Standard_LRS'),
            kind='BlobStorage',
            location=self._location,
            encryption=encryption, 
            access_tier='Cool',
            enable_https_traffic_only=True)

        self._logger.info('creating storage account using rg: {} and account name: {}'.format(
            self._vdc_storage_account_resource_group,
            self._vdc_storage_account_name))
    
        async_operation = self._storage_management_client.storage_accounts.create(
            self._vdc_storage_account_resource_group,
            self._vdc_storage_account_name,
            parameters)
        
        async_operation.wait()

        self._logger.info('vdc storage created')

    def get_storage_account_key(self):
        """Function that retrieves a storage account key.
        
        :return: storage account key
        :rtype: str
        :raises: :class:`Exception`
        """

        storage_keys = \
            self._storage_management_client\
                .storage_accounts.list_keys(
                    self._vdc_storage_account_resource_group,
                    self._vdc_storage_account_name)
        
        storage_keys = {v.key_name: v.value for v in storage_keys.keys}
        
        self._vdc_storage_account_key = storage_keys['key1']

        return self._vdc_storage_account_key

    def store_contents(
        self,
        content_type: ContentType,
        container_name: str,
        content_name: str,
        content_data: str = None,
        content_path: str = None):
        """Function that stores file content. Based on the ContentType the function
        can either save a text or can read a file path (content_path) and copies it

        :param content_type: Content type, can be file or text
        :type content_type: enum
        :param container_name: Container name
        :type container_name: str
        :param content_name: File name
        :type content_name: str
        :param content_data: File content as text
        :type content_data: str
        :param content_path: File path to be copied into the storage
        :type content_path: str
        
        :raises: :class:`CustomException`
        """

        try:
            self._logger.info('storing contents')

            if self._vdc_storage_account_key == None:
                self._vdc_storage_account_key = self.get_storage_account_key()

            block_blob_service = BlockBlobService(
                account_name=self._vdc_storage_account_name, 
                account_key=self._vdc_storage_account_key)

            # Create container if does not exists
            if not block_blob_service.exists(container_name):
                self._logger.info('container {} does not exists, proceeding to create it'.format(
                    container_name))
                block_blob_service.create_container(container_name)
           
            self._logger.info('saving blob')

            if content_type == ContentType.TEXT:
                block_blob_service.create_blob_from_text(
                    container_name=container_name, 
                    blob_name=content_name,
                    text=content_data)
            elif content_type == ContentType.FILE:
                if Path(content_path).exists():
                    block_blob_service.create_blob_from_path(
                        container_name=container_name, 
                        blob_name=content_name,
                        file_path=content_path)
                else:
                    raise CustomException('File does not exist.')


        except Exception as ex:
            raise CustomException(
                'There was an unhandled exception: {}'.format(str(ex)))

    def get_contents(
        self,
        content_type: ContentType,
        container_name: str,
        content_name: str):
        """Function that retrieves the content data, based on the content type.
        Currently, it only retrieves text content data

        :param content_type: Content type, can be file or text
        :type content_type: enum
        :param container_name: Container name
        :type container_name: str
        :param content_name: File name
        :type content_name: str

        :raises: :class:`CustomException`
        """

        if content_type == ContentType.TEXT:
            try:
                if self._vdc_storage_account_key == None:
                    self._vdc_storage_account_key = self.get_storage_account_key()

                block_blob_service = BlockBlobService(
                    account_name=self._vdc_storage_account_name, 
                    account_key=self._vdc_storage_account_key)

                response: Blob = block_blob_service.get_blob_to_text(
                    container_name=container_name, 
                    blob_name=content_name)

                return response.content
            
            except Exception as ex:
                raise CustomException(
                    'There was an unhandled exception: {}'.format(str(ex)))

    def get_sas_key(self):
        """Function that retrieves a sas key. The default expiration is set to 24 hours
        
        :return: A Shared Access Signature (sas) token. 
        :rtype: str
        :raises: :class:`Exception`
        """

        expiry = datetime.now() + timedelta(hours=24)

        if self._vdc_storage_account_key == None:
                self._vdc_storage_account_key = self.get_storage_account_key()
        
        block_blob_service = BlockBlobService(
            account_name=self._vdc_storage_account_name, 
            account_key=self._vdc_storage_account_key)

        return block_blob_service.generate_account_shared_access_signature(
            ResourceTypes.OBJECT,
            AccountPermissions.READ,
            expiry,
            protocol="https")
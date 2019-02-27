from azure.mgmt.resource import ( 
    ManagementLockClient
)
from azure.mgmt.resource.locks.models import (
    ManagementLockObject, 
    ManagementLockObjectPaged
)

from exceptions.custom_exception import CustomException
import sys
import logging

class ManagementLockClientSdk(object):
    
    # Logging preparation.
    #-----------------------------------------------------------------------------

    # Retrieve the main logger; picks up parent logger instance if invoked as a module.
    _logger = logging.getLogger(__name__)

    def __init__(
        self,
        resource_lock_client: ManagementLockClient):

        self._resource_lock_client = resource_lock_client

    def delete_all_resource_group_locks(
        self,
        resource_group_name: str):
        """Function that deletes all locks from a resource group

        :param resource_group_name: Resource group name to analyze
        :type resource_group_name: str

        :raises: :class:`Exception`
        """

        all_locks = \
            self.get_resource_group_locks(resource_group_name)
        self._logger\
            .debug('The following locks were found: {}'.format(
            all_locks))
        
        if len(all_locks) > 0:
            for lock_id in all_locks:
                self._logger.debug('About to delete the following lock: {}'.format(
                    lock_id))

                self.delete_resource_group_lock_by_id(lock_id)
        else:
            self._logger.info('No locks found in resource group: {}'.format(resource_group_name))

    def delete_resource_group_lock_by_id(
        self,
        lock_id: str):
        """Function that deletes a lock from a resource group

        :param lock_id: Lock id to delete
        :type lock_id: str

        :raises: :class:`Exception`
        """
        
        # A lock id looks like this:
        # '/subscriptions/cf0c53fb-06f5-4fe3-9c25-cabce6811cb1/resourcegroups/validate-sharedsvcs-kv-rg/providers/Microsoft.Storage/storageAccounts/validatesharedsvcskvdia/providers/Microsoft.Authorization/locks/storageDoNotDelete'
        limiter = '/providers/Microsoft.Authorization/locks/'
        scopeIndex = lock_id.index(limiter)
        lockNameIndex = lock_id.index(limiter) + len(limiter)
        
        scope = lock_id[1: scopeIndex] # subscriptions/cf0c53fb-06f5-4fe3-9c25-cabce6811cb1/resourcegroups/validate-sharedsvcs-kv-rg/providers/Microsoft.Storage/storageAccounts/validatesharedsvcskvdia
        lockName = lock_id[lockNameIndex: len(lock_id)] # storageDoNotDelete
        result = self._resource_lock_client.management_locks.delete_by_scope(
            scope,
            lockName,
            raw=True)
            
        self._logger\
            .debug('HTTP Response: {}'.format(result.response))
    
    def get_resource_group_locks(
        self,
        resource_group_name: str) -> list:
        """Function that retrieves all the locks of a given resource group

        :param resource_group_name: Resource group name to analyze
        :type resource_group_name: str

        :return: list of lock identifiers
        :rtype: list

        :raises: :class:`Exception`
        """
        all_locks: ManagementLockObjectPaged = \
            self._resource_lock_client\
                .management_locks\
                .list_at_resource_group_level(
                    resource_group_name)
        
        all_lock_ids = list()
        
        if all_locks is not None:            
            move_next_page = True
            while move_next_page:
                               
                for management_lock_object in all_locks.current_page:
                    all_lock_ids.append(management_lock_object.id)
               
                if all_locks.next_link is None:
                    move_next_page = False
                else:
                    all_locks.advance_page()

        return all_lock_ids
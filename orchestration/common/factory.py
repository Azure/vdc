from orchestration.data.idata import DataInterface
from orchestration.models.storage_type import StorageType
from orchestration.models.integration_type import IntegrationType
from orchestration.models.sdk_type import SdkType
from azure.common.credentials import (
    BasicTokenAuthentication,
    UserPassCredentials,
    ServicePrincipalCredentials
)

class ObjectFactory(object):

    def __init__(
        self,
        is_live_mode: bool):
        self.is_live_mode = is_live_mode
    
    def storage_factory(
        self, 
        storage_type: StorageType, 
        **kwargs) -> DataInterface: 
        
        if storage_type == StorageType.BLOB_STORAGE:
            from azure.mgmt.storage import StorageManagementClient
            storage_management_client = \
                self._create_azure_sdk_mgmt_client(
                    StorageManagementClient,
                    **kwargs)
            resource_management_integration_service = \
                self.integration_factory(
                    IntegrationType.RESOURCE_MANAGEMENT_CLIENT_SDK,
                    **kwargs)
            from orchestration.data.blob_storage import BlobStorage
            return BlobStorage(
                storage_management_client,
                resource_management_integration_service,
                kwargs['location'],
                storage_account_name=kwargs['storage_account_name'],
                storage_account_resource_group=kwargs['storage_account_resource_group'])
        else:
            raise NotImplementedError()

    def integration_factory(
        self,
        integration_type: IntegrationType, 
        **kwargs):

        if integration_type == IntegrationType.RESOURCE_MANAGEMENT_CLIENT_SDK:
            from azure.mgmt.resource import ResourceManagementClient
            from orchestration.integration.sdk.resource_management_client import ResourceManagementClientSdk
            
            return ResourceManagementClientSdk(
                    self._create_azure_sdk_mgmt_client(
                        ResourceManagementClient,
                        **kwargs))
        elif integration_type == IntegrationType.POLICY_CLIENT_SDK:
            from azure.mgmt.resource.policy import PolicyClient
            from orchestration.integration.sdk.policy_client import PolicyClientSdk
            
            return PolicyClientSdk(
                    self._create_azure_sdk_mgmt_client(
                        PolicyClient,
                        **kwargs))
        elif integration_type == IntegrationType.MANAGEMENT_LOCK_CLIENT_SDK:
            from azure.mgmt.resource import ManagementLockClient
            from orchestration.integration.sdk.management_lock_client import ManagementLockClientSdk
            
            return ManagementLockClientSdk(
                    self._create_azure_sdk_mgmt_client(
                        ManagementLockClient,
                        **kwargs))
        elif integration_type == IntegrationType.SUBSCRIPTION_CLIENT_SDK:
            from azure.mgmt.subscription import SubscriptionClient
            from orchestration.integration.sdk.subscription_client import SubscriptionClientSdk
            
            return SubscriptionClientSdk(
                    self._create_azure_sdk_mgmt_client(
                        SubscriptionClient,
                        **kwargs))
        elif integration_type == IntegrationType.MANAGEMENT_GROUP_CLIENT_SDK:
            from azure.mgmt.managementgroups import ManagementGroupsAPI
            from orchestration.integration.sdk.management_group_client import ManagementGroupClientSdk
            
            return ManagementGroupClientSdk(
                    self._create_azure_sdk_mgmt_client(
                        ManagementGroupsAPI,
                        **kwargs))
        elif integration_type == IntegrationType.BILLING_CLIENT_SDK:
            from azure.mgmt.billing import BillingManagementClient
            from orchestration.integration.sdk.billing_client import BillingClientSdk
            
            return BillingClientSdk(
                    self._create_azure_sdk_mgmt_client(
                        BillingManagementClient,
                        **kwargs))
        elif integration_type == IntegrationType.AAD_CLIENT_CLI:
            from orchestration.integration.cli.aad_client import AADClientCli
            return AADClientCli()
        elif integration_type == IntegrationType.KEYVAULT_CLIENT_CLI:
            from orchestration.integration.cli.keyvault_client import KeyVaultClientCli
            return KeyVaultClientCli()
        elif integration_type == IntegrationType.RBAC_CLIENT_CLI:
            from orchestration.integration.cli.rbac_client import RBACClientCli
            return RBACClientCli()
        elif integration_type == IntegrationType.RESOURCE_MANAGEMENT_CLIENT_CLI:
            from orchestration.integration.cli.resource_management_client import ResourceManagementClientCli
            return ResourceManagementClientCli()
        elif integration_type == IntegrationType.SUBSCRIPTION_CLIENT_CLI:
            from orchestration.integration.cli.subscription_client import SubscriptionClientCli
            return SubscriptionClientCli()
        else:
            raise NotImplementedError()
    
    def get_module_version_retrieval(
        self,
        main_module: str):
        from orchestration.common.module_version import ModuleVersionRetrieval
        return \
            ModuleVersionRetrieval(
                        main_module = main_module,
                        local_file_finder = self.get_local_file_finder(),
                        remote_file_finder = self.get_remote_file_finder())

    def get_local_file_finder(self):
        from orchestration.common.local_file_finder import LocalFileFinder
        return LocalFileFinder()

    def get_remote_file_finder(self):
        from orchestration.common.remote_file_finder import RemoteFileFinder
        return RemoteFileFinder()

    def get_parameter_initializer(self):
        from orchestration.common.parameter_initializer import ParameterInitializer
        return ParameterInitializer()

    def _create_azure_sdk_mgmt_client(
        self,
        client_class,
        **kwargs):
        
        if not self.is_live_mode:            
            credentials = BasicTokenAuthentication(
                token = {
                    'access_token':'faked_token'
                })
            
            if 'subscription_id' in kwargs:
                client = client_class(
                        credentials, 
                        kwargs['subscription_id'])
            else:
                client = client_class(
                    credentials)

            client.config.long_running_operation_timeout = 0
        else:
            if kwargs is not None and \
                len(kwargs) > 0 and \
                'client_id' in kwargs and \
                kwargs['client_id'] is not None and \
                'secret' in kwargs and \
                kwargs['secret'] is not None:

                credentials = \
                ServicePrincipalCredentials(
                    client_id=kwargs['client_id'], 
                    secret=kwargs['secret'], 
                    tenant=kwargs['tenant_id'])
                
                if 'subscription_id' in kwargs:
                    client = client_class(
                        credentials, 
                        kwargs['subscription_id'])
                else:
                    client = client_class(credentials)
            else:
                from azure.common.client_factory import get_client_from_cli_profile
                # No credentials passed, let's attempt to get the credentials from az login
                if 'subscription_id' in kwargs:
                    client = get_client_from_cli_profile(
                        client_class,
                        subscription_id=kwargs['subscription_id'])
                else:
                    client = get_client_from_cli_profile(
                        client_class)

        return client
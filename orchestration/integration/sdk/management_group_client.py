from azure.mgmt.managementgroups.models import (
    CreateManagementGroupRequest,
    CreateManagementGroupChildInfo
)
from azure.mgmt.managementgroups import ManagementGroupsAPI

class ManagementGroupClientSdk(object):
    
    def __init__(
        self,
        management_group_client: ManagementGroupsAPI):
        self._management_group_client = \
            management_group_client
    
    def create_management_group(
        self,
        management_group_id: str,
        subscription_id: str):
        """Function that creates a management group.

        :param management_group_id: Management Group Identifier
        :type management_group_id: str
        :param subscription_id: Subscription identifier
        :type subscription_id: str
        """
        
        resource_group_request = CreateManagementGroupRequest()
        resource_group_request.name = management_group_id
        
        self._management_group_client\
            .management_groups\
            .create_or_update(
                group_id=management_group_id,
                create_management_group_request=resource_group_request)\
            .wait()
    
        if subscription_id is not None:

            self.associate_subscription_to_management_group(
                management_group_id=management_group_id,
                subscription_id=subscription_id)            

    def get_management_group(
        self,
        management_group_id: str):
        """Function that gets a management group.

        :param management_group_id: Management Group Identifier
        :type management_group_id: str
        """
        self._management_group_client\
            .management_groups\
            .get(group_id=management_group_id)

    def associate_subscription_to_management_group(
        self,
        management_group_id: str,
        subscription_id: str):
        """Function that associates a subscription to a management group.

        :param management_group_id: Management Group Identifier
        :type management_group_id: str
        :param subscription_id: Subscription identifier
        :type subscription_id: str
        """
        self._management_group_client\
            .management_group_subscriptions\
            .create(
                group_id=management_group_id,
                subscription_id=subscription_id)
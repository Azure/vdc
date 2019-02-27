from orchestration.integration.sdk.subscription_client import SubscriptionClientSdk
from orchestration.integration.sdk.billing_client import BillingClientSdk
from orchestration.integration.sdk.management_group_client import ManagementGroupClientSdk

class SubscriptionManagement(object):

    def __init__(
        self,
        management_group_integration_service: ManagementGroupClientSdk,
        subscription_integration_service: SubscriptionClientSdk,
        billing_integration_service: BillingClientSdk):
        
        self._management_group_integration_service = \
            management_group_integration_service
        self._subscription_integration_service = \
            subscription_integration_service
        self._billing_integration_service = \
            billing_integration_service

    def create_subscription(
        self,
        offer_type: str,
        subscription_name: str,
        billing_enrollment_name: str = None,
        deployment_user_id: str = None):
        """Function creates a subscription by providing an offer type.
        If the subscription name already exists, it does not create a new one

        :param offer_type: Subscription offer type
        :type offer_type: str
        :param subscription_name: Subscription name
        :type subscription_name: str
        :param billing_enrollment_name (optional): Billing enrollment name,
        if no value is passed, the first billing enrollment found will be
        used
        :type billing_enrollment_name: list
        :param deployment_user_id: SPN or AAD User's Object Id. If passed, this SPN or Object Id will become owner of the subscription
        :type deployment_user_id: str
        """
        
        #if self.get_subscription(subscription_name) is None:
        if billing_enrollment_name is None:
            # No billing enrollment passed, get the first one by default

            all_billing_enrollments = \
                self._billing_integration_service\
                    .get_all_billing_enrollments()

            if all_billing_enrollments is None or \
                len(all_billing_enrollments) == 0:
                raise ValueError('No billing enrollments found')
            else:
                billing_enrollment_name = \
                    all_billing_enrollments[0]
        else:

            # Validate that billing enrollment exists
            billing_enrollment = \
                self._billing_integration_service\
                    .get_billing_enrollment_name(
                    billing_enrollment_name)

            if billing_enrollment == '':
                raise \
                    ValueError('No billing enrollments found, searched: {}'\
                        .format(billing_enrollment_name))

        return self._subscription_integration_service\
            .create_subscription(
                offer_type=offer_type,
                subscription_name=subscription_name,
                billing_enrollment_name=billing_enrollment_name,
                deployment_user_id=deployment_user_id)        

    def delete_subscription(
        self,
        args):
        
        raise NotImplementedError()

    def create_management_group(
        self,
        management_group_id: str,
        subscription_id: str = None,
        subscription_name: str = None):
        """Function that creates a management group. If subscription_id is passed, the function will
        attempt to associate the management group with the subscription.
        If subscription name is passed, the function will attempt to retrieve the subscription id 
        by its name, if no subscription is found, then no subscription association will occur.
        The recommendation is to pass a subscription_id to prevent an additional API call.

        :param management_group_id: Management Group Identifier
        :type management_group_id: str
        :param subscription_id: (Optional) Subscription Identifier, if passed, 
        the function associates the subscription with the Management Group
        :type subscription_id: str
        :param subscription_name: (Optional) Subscription Name, if passed, 
        the function will make an API call to retrieve the subscription id, 
        then associates the subscription with the Management Group
        :type subscription_name: str
        """

        if subscription_name is not None:
            subscription = \
                self._subscription_integration_service\
                    .get_subscription_by_name(
                        subscription_name)

            if subscription is not None:
                subscription_id = subscription['subscription_id']
            else:
                subscription_id = None

        self._management_group_integration_service\
            .create_management_group(
                management_group_id=management_group_id,
                subscription_id=subscription_id)

    def get_subscription(
        self,
        subscription: str):
        """Function that retrieves a subscription based on its value.
            Subscription can be either an id or displayName. The code
            will attempt to retrieve the subscription by id first, if no
            subscriptions is found, then the code attempts to retrieve
            the subscription by name.

        :param subscription: Subscription Id or Subscription Name
        :type subscription: str
        """

        subscription_found = None

        subscription_found = \
            self._subscription_integration_service\
                .get_subscription_by_id(subscription)
        
        if subscription_found is None:
            subscription_found = \
                self._subscription_integration_service\
                    .get_subscription_by_name(subscription)

        return subscription_found

    def get_management_group(
        self,
        management_group_id: str):
        """Function that gets a management group.

        :param management_group_id: Management Group Identifier
        :type management_group_id: str
        """
        self._management_group_integration_service\
            .get_management_group(
                management_group_id=management_group_id)

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

        self._management_group_integration_service\
            .associate_subscription_to_management_group(
                management_group_id=management_group_id,
                subscription_id=subscription_id)
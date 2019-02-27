from azure.mgmt.subscription import SubscriptionClient
from azure.mgmt.subscription.models import (
    SubscriptionCreationParameters,
    Subscription,
    SubscriptionCreationResult
)
import sys
import logging
import json

class SubscriptionClientSdk(object):

    # Logging preparation.
    #-----------------------------------------------------------------------------

    # Retrieve the main logger; picks up parent logger instance if invoked as a module.
    _logger = logging.getLogger(__name__)

    def __init__(
        self,
        subscription_client: SubscriptionClient):
        
        self._subscription_client = \
            subscription_client

    def create_subscription(
        self,
        offer_type: str,
        subscription_name: str,
        billing_enrollment_name: str,
        deployment_user_id: str = None):
        """Function creates a subscription by providing an offer type.

        :param offer_type: Subscription offer type
        :type offer_type: str
        :param subscription_name: Subscription name
        :type subscription_name: str
        :param billing_enrollment_name: Billing enrollment name
        :type billing_enrollment_name: str
        :return subscription link
        :rtype str
        """
        from azure.mgmt.subscription.models import AdPrincipal

        ad_principals = None

        if deployment_user_id is not None:
            ad_principal = AdPrincipal(object_id=deployment_user_id)
            ad_principals = [ad_principal]

        creation_parameters = SubscriptionCreationParameters(
            offer_type=offer_type,
            display_name=subscription_name,
            owners=ad_principals)
 
        subscription_async_operation = \
        self._subscription_client\
                .subscription_factory\
                .create_subscription_in_enrollment_account(
                    enrollment_account_name=billing_enrollment_name,
                    body=creation_parameters)

        # Wait for the resource provisioning to complete
        subscription_async_operation.wait()
        subscription_result: SubscriptionCreationResult = \
            subscription_async_operation.result()

        return subscription_result.subscription_link
        
    def get_subscription_by_id(
        self, 
        subscription_id: str):
        """Function that gets a subscription by its subscription id.

        :param subscription_id: Subscription identifier
        :type subscription_id: str
        :return subscription dictionary containing two properties: display_name and subscription_id
        :rtype dict
        """
        subscription = \
            self._subscription_client\
                .subscriptions.get(
                    subscription_id = subscription_id)

        if subscription is not None:
            return dict({
                    'display_name': subscription.display_name, 
                    'subscription_id': subscription.subscription_id
                })
        else:
            return None

    def get_subscription_by_name(
        self,
        subscription_name: str) -> dict:
        """Function that gets a subscription by its subscription name.
        If no subscription is found, None is returned.

        :param subscription_name: Subscription name
        :type subscription_name: str
        :return subscription dictionary containing two properties: display_name and subscription_id
        :rtype dict
        """
        all_subscriptions = self.get_all_subscriptions()

        if subscription_name in all_subscriptions:
            return all_subscriptions[subscription_name]
        else:
            return None

    def get_all_subscriptions(self) -> list:
        """Function that gets all subscriptions.
        :return A list of dictionaries containing two properties: display_name and subscription_id
        :rtype: list<dict>
        """
        subscriptions = \
            self._subscription_client\
                .subscriptions\
                .list()

        all_subscriptions = list()

        if subscriptions is not None:            
            move_next_page = True

            while move_next_page:

                for subscription in subscriptions.current_page:
                    all_subscriptions.append(dict({
                        'display_name': subscription.display_name, 
                        'subscription_id': subscription.subscription_id
                    }))
               
                if subscriptions.next_link is None:
                    move_next_page = False
                else:
                    subscriptions.advance_page()

        return all_subscriptions
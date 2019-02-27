from tools.devtools_testutils.base_replayable_test_case import VDCBaseTestCase
from tools.devtools_testutils.base_integration_test_case import BaseIntegrationTestCase
from orchestration.subscription_management import SubscriptionManagement
from orchestration.common.factory import ObjectFactory
from orchestration.models.integration_type import IntegrationType
from orchestration.models.sdk_type import SdkType
import unittest

class SubscriptionManagementTests(BaseIntegrationTestCase):
    
    _subscription_management: SubscriptionManagement

    def setUp(self):
        super(SubscriptionManagementTests, self).setUp()
        object_factory = \
            ObjectFactory(is_live_mode=self.is_live)
        client_id = None
        secret = None
        tenant_id = None
        management_group_integration_service = \
            object_factory.integration_factory(
                IntegrationType.MANAGEMENT_GROUP_CLIENT_SDK,
                client_id=client_id,
                secret=secret,
                tenant_id=tenant_id)

        subscription_integration_service = \
            object_factory.integration_factory(
                IntegrationType.SUBSCRIPTION_CLIENT_SDK,
                client_id=client_id,
                secret=secret,
                tenant_id=tenant_id)

        # Setting a dummy subscription Id, this is to prevent
        # billing client sdk instance from failing.
        # If you are running in live mode, make sure to update
        # subscription_id with a valid value
        billing_integration_service = \
            object_factory.integration_factory(
                IntegrationType.BILLING_CLIENT_SDK,
                client_id=client_id,
                secret=secret,
                tenant_id=tenant_id,
                subscription_id='00000000-0000-0000-0000-000000000000')
        
        self._subscription_management = SubscriptionManagement(
            management_group_integration_service,
            subscription_integration_service,
            billing_integration_service)
    
    def test_create_management_group(self):
        
        self._subscription_management\
            .create_management_group(
                management_group_id='mgmtgrpglobal')

    def test_update_management_group_assign_subscription(self):
        
        subscription_link = self._subscription_management\
            .create_subscription(
                offer_type="MS-AZR-0017P",
                subscription_name='TestSubscription01',
                deployment_user_id='00000000-0000-0000-0000-000000000000')
        
        self._subscription_management\
            .create_management_group(
                management_group_id='mgmtgrpglobal',
                subscription_id= subscription_link.replace('/subscriptions/', ''))
        
        self.assertIsNot(subscription_link, '')
        self.assertIsNotNone(subscription_link)

    def test_create_subscription(self):
        
        subscription_link = self._subscription_management\
            .create_subscription(
                offer_type="MS-AZR-0017P",
                subscription_name='TestSubscription02',
                deployment_user_id='00000000-0000-0000-0000-000000000000')

        self.assertIsNot(subscription_link, '')
        self.assertIsNotNone(subscription_link)
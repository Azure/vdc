from pathlib import Path
from sys import argv
from argparse import ArgumentParser, FileType
from orchestration.subscription_management import SubscriptionManagement
from orchestration.common.factory import ObjectFactory
from orchestration.models.integration_type import IntegrationType
from orchestration.models.sdk_type import SdkType
from logging.config import dictConfig
import logging
import json

# Logging preperation.
#-----------------------------------------------------------------------------

# Set the log configuration using a json config file.        
if Path('logging/config.json').exists():
    with open('logging/config.json', 'rt') as f:
        config = json.load(f)
        dictConfig(config)
else:
    logging.basicConfig(level=logging.INFO)

# Create a new logger instance using the provided configuration.
_logger = logging.getLogger(__name__)

def create_subscription(args):

    object_factory = ObjectFactory(is_live_mode=True)
        
    management_group_integration_service = \
        object_factory.integration_factory(
            IntegrationType.MANAGEMENT_GROUP_CLIENT,
            client_id=args.client_id,
            secret=args.secret,
            tenant_id=args.tenant_id)

    subscription_integration_service = \
        object_factory.integration_factory(
            IntegrationType.SUBSCRIPTION_CLIENT,
            client_id=args.client_id,
            secret=args.secret,
            tenant_id=args.tenant_id)

    billing_integration_service = \
        object_factory.integration_factory(
            IntegrationType.BILLING_CLIENT,
            client_id=args.client_id,
            secret=args.secret,
            tenant_id=args.tenant_id)

    subscription_management = \
        SubscriptionManagement(
            management_group_integration_service,
            subscription_integration_service,
            billing_integration_service)

    subscription_link = \
        subscription_management.create_subscription(
                offer_type=args.offer_type,
                billing_enrollment_name=args.billing_enrollment_name,
                subscription_name=args.subscription_name)
    import sys
    sys.stdout.write(subscription_link)

    _logger.info("Subscription successfully created")

def create_management_group(args):

    object_factory = ObjectFactory(is_live_mode=True)
        
    management_group_integration_service = \
        object_factory.integration_factory(
            IntegrationType.MANAGEMENT_GROUP_CLIENT,
            client_id=args.client_id,
            secret=args.secret,
            tenant_id=args.tenant_id)

    subscription_integration_service = \
        object_factory.integration_factory(
            IntegrationType.SUBSCRIPTION_CLIENT,
            client_id=args.client_id,
            secret=args.secret,
            tenant_id=args.tenant_id)

    billing_integration_service = \
        object_factory.integration_factory(
            IntegrationType.BILLING_CLIENT,
            client_id=args.client_id,
            secret=args.secret,
            tenant_id=args.tenant_id)

    subscription_management = \
        SubscriptionManagement(
            management_group_integration_service,
            subscription_integration_service,
            billing_integration_service)
    
    subscription_management.create_management_group(
        management_group_id=args.id,
        subscription_id=args.subscription_id,
        subscription_name=args.subscription_name)

    import sys
    sys.stdout.write(args.id)

    _logger.info("Management group successfully created")

def associate_mgmt_group(args):
    object_factory = ObjectFactory(is_live_mode=True)
        
    management_group_integration_service = \
        object_factory.integration_factory(
            IntegrationType.MANAGEMENT_GROUP_CLIENT,
            client_id=args.client_id,
            secret=args.secret,
            tenant_id=args.tenant_id)

    subscription_integration_service = \
        object_factory.integration_factory(
            IntegrationType.SUBSCRIPTION_CLIENT,
            client_id=args.client_id,
            secret=args.secret,
            tenant_id=args.tenant_id)

    billing_integration_service = \
        object_factory.integration_factory(
            IntegrationType.BILLING_CLIENT,
            client_id=args.client_id,
            secret=args.secret,
            tenant_id=args.tenant_id)

    subscription_management = \
        SubscriptionManagement(
            management_group_integration_service,
            subscription_integration_service,
            billing_integration_service)
    
    subscription_management\
        .associate_subscription_to_management_group(
            management_group_id=args.management_group_id,
            subscription_id=args.subscription_id)

    _logger.info("Subscription successfully associated to Management group")

def set_general_arguments(parser):
    parser.add_argument('--client-id',
                dest='client_id',
                action="store",
                type=str,
                required=False,                
                help='Specifies the ClientId. This value can be a SPN or AAD Object ID')

    parser.add_argument('--secret',
                dest='secret',
                action="store",
                type=str,
                required=False,                
                help="Specifies the ClientId's secret")

    parser.add_argument('--tenant-id',
                dest='tenant_id',
                action="store",
                type=str,
                required=False,                
                help='Specifies the TenantId')

def main():
    
    #-----------------------------------------------------------------------------
    # Script argument definitions.
    #-----------------------------------------------------------------------------

    # Define a top level parser.
    parser = ArgumentParser(
        description='Set of commands to manage Azure Subscriptions')
    
    subparsers = parser.add_subparsers()

    create_subscription_parser = subparsers.add_parser(
        'create-subscription',
        help='Creates a new subscription')
    
    create_subscription_parser\
    .add_argument(
        '--offer-type',
        dest='offer_type',
        action='store',
        type=str,
        required=True,                
        help="Azure's Subscription Offer Type: i.e. MS-AZR-0017P")

    create_subscription_parser\
    .add_argument(
        '--subscription-name',
        dest='subscription_name',
        action='store',
        type=str,
        required=True,                
        help="Azure's Subscription Name")

    create_subscription_parser\
    .add_argument(
        '--billing-enrollment-name',
        dest='billing_enrollment_name',
        action='store',
        type=str,
        required=False,                
        help="Billing enrollment guid. If no value is passed, a default billing enrollment account will be used")
    
    set_general_arguments(create_subscription_parser)

    create_subscription_parser\
    .set_defaults(
        func=create_subscription)

    subparsers = parser.add_subparsers()

    create_management_group_parser = subparsers.add_parser(
        'create-management-group',
        help='Creates a new management group')
    
    create_management_group_parser\
    .add_argument(
        '--id',
        dest='id',
        action='store',
        type=str,
        required=True,                
        help="Management Group Id")

    create_management_group_parser\
    .add_argument(
        '--subscription-id',
        dest='subscription_id',
        action='store',
        default=None,
        type=str,
        required=False,                
        help="Subscription Id, if specified, the subscription gets associated to the management group")

    create_management_group_parser\
    .add_argument(
        '--subscription-name',
        dest='subscription_name',
        action='store',
        default=None,
        type=str,
        required=False,                
        help="Subscription Name, if specified, the subscription gets associated to the management group")

    set_general_arguments(create_management_group_parser)

    create_management_group_parser\
    .set_defaults(
        func=create_management_group)

    associate_mgmt_group_parser = subparsers.add_parser(
        'associate-management-group',
        help='Associates a subscription to a management group')

    associate_mgmt_group_parser\
    .add_argument(
        '--subscription-id',
        dest='subscription_id',
        action='store',
        type=str,
        required=True,                
        help="Azure's Subscription Id")

    associate_mgmt_group_parser\
    .add_argument(
        '--management-group-id',
        dest='management_group_id',
        action='store',
        type=str,
        required=True,                
        help="Azure's Management Group Id")

    associate_mgmt_group_parser\
    .set_defaults(
        func=associate_mgmt_group)
    
    #-----------------------------------------------------------------------------
    # Process parameter arguments.
    #-----------------------------------------------------------------------------

    # Gather the provided argument within an array.
    args = parser.parse_args()

    # Let's check if there are parameters passed, if not, print function usage
    if len(vars(args)) == 0:
        parser.print_usage()
        exit()
    
    args.func(args)
    
    #-----------------------------------------------------------------------------
    # Call the function indicated by the invocation command.
    #-----------------------------------------------------------------------------
    try:
        args.func(args)
    except Exception as ex:
        _logger.error('There was an error provisioning the resources: {}'.format(str(ex)))
        _logger.error(ex)
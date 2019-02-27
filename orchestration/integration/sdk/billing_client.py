
from azure.mgmt.billing import BillingManagementClient
from azure.mgmt.billing.models import EnrollmentAccount

class BillingClientSdk(object):

    def __init__(
        self, 
        billing_client: BillingManagementClient):
        self._billing_client = billing_client

    def get_all_billing_enrollments(self) -> list:
        """Function that gets all billing enrollments.

        :return A list of string containing billing enrollment account name
        :rtype: list
        """
        enrollment_accounts = \
            self._billing_client\
                .enrollment_accounts\
                .list()
        
        all_enrollments = list()

        if enrollment_accounts is not None:            
            move_next_page = True

            while move_next_page:

                for enrollment_account in enrollment_accounts.current_page:
                    all_enrollments.append(enrollment_account.name)
               
                if enrollment_accounts.next_link is None:
                    move_next_page = False
                else:
                    enrollment_accounts.advance_page()

        return all_enrollments
        
    def get_billing_enrollment_name(
        self,
        billing_enrollment_name: str) -> str:
        """Function that retrieves a billing enrollment name based on its name

        :param billing_enrollment_name: Billing enrollment name
        :type billing_enrollment_name: str
        :return Billing enrollment name
        :rtype: str
        """
        enrollment_account: EnrollmentAccount = \
            self._billing_client\
                .enrollment_accounts\
                .get(billing_enrollment_name)
        
        if enrollment_account is not None:
            enrollment_account.name
        else:
            return ''
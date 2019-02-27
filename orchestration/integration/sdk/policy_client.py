from azure.mgmt.resource.policy.models import (
    PolicyDefinition, 
    PolicyAssignment
)
from azure.mgmt.resource.policy import PolicyClient
import sys
import logging
import json

class PolicyClientSdk(object):

    # Logging preparation.
    #-----------------------------------------------------------------------------

    # Retrieve the main logger; picks up parent logger instance if invoked as a module.
    _logger = logging.getLogger(__name__)

    def __init__(
        self,
        policy_client: PolicyClient):
        self._policy_client = policy_client

    def create_and_assign_policy(
        self,
        scope: str,
        policies: dict,
        deployment_parameters: dict):
        """Function creates and assigns policies by reading a file located in policies/shared-services|workload/arm.policies.json (subscription level) or
        policies/shared-services|workload/resource/arm.policies.json (resource group level)

        :param scope: Scope of the policy assignment
        :type scope: str
        :param policies: Policies (json deserialized) object
        :type policies: dict
        :param deployment_parameters: Deployment parameters used to replace tokens, if any exists in the policy file(s)
        :type deployment_parameters: dict
        
        :raises: :class:`Exception`
        """
        
        try:
              
            for policy in policies:
                
                policy_creation_parameters: PolicyDefinition = \
                    PolicyDefinition()
                
                policy_assignment_parameters: PolicyAssignment = \
                    PolicyAssignment()
                
                policy_definition_id = ''
                
                if 'policyDefinitionId' not in policy or \
                    len(policy['policyDefinitionId']) == 0:
                    policy_creation_parameters\
                        .policy_rule = policy['rules']
                    policy_creation_parameters\
                        .display_name = policy['name']
                    policy_creation_parameters\
                        .description = policy['description'] 
                    policy_creation_parameters\
                        .metadata = dict({
                            'category': 'VDC'
                        })

                    if 'parameters' in policy:
                        policy_creation_parameters\
                            .parameters = policy['parameters']

                    policy_creation_return = \
                        self._policy_client\
                            .policy_definitions\
                            .create_or_update(
                                policy['name'],
                                policy_creation_parameters)

                    policy_definition_id =\
                         policy_creation_return.id
                    
                    # Let's create policy assignment object
                    policy_assignment_parameters\
                        .name = \
                            policy['name']

                    policy_assignment_parameters\
                        .display_name = \
                            policy['name']
                else:
                    policy_definition_id = \
                        policy['policyDefinitionId']
                
                policy_assignment_parameters\
                    .policy_definition_id = \
                        policy_definition_id

                # Assign policies if there are no policy parameters
                # or if there are policy parameters plus parameters-value
                # parameters-value contains the values corresponding to
                # the different policy parameters
                if  'policyDefinitionId' in policy or\
                    'parameters' not in policy or \
                   ('parameters' in policy and \
                    'parameters-value' in policy):
                    
                    if 'parameters-value' in policy:
                        policy_assignment_parameters\
                            .parameters = \
                                policy['parameters-value']
                    
                    try:
                        self._policy_client\
                        .policy_assignments\
                        .create(
                            scope,
                            policy['name'],
                            policy_assignment_parameters)
                    except Exception as ex:
                        print(str(ex))
                    

        except Exception as ex:
            self._logger.error('There was an error while creating/assigning policies')
            self._logger.error(ex)
            raise ex 
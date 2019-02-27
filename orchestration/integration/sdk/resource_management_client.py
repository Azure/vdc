from azure.mgmt.resource import (
    ResourceManagementClient
)
from azure.mgmt.resource.resources.models import ResourceGroup
from exceptions.custom_exception import CustomException
import sys
import logging


class ResourceManagementClientSdk(object):
    
    # Logging preparation.
    #-----------------------------------------------------------------------------

    # Retrieve the main logger; picks up parent logger instance if invoked as a module.
    _logger = logging.getLogger(__name__)

    def __init__(
        self,
        resource_management_client: ResourceManagementClient):
        
        self._resource_management_client = \
            resource_management_client

    def create_or_update_deployment(
        self, 
        mode: str, 
        template: dict, 
        parameters: dict,
        resource_group_name: str,
        deployment_name: str):
        """Function that executes the resource deployment

        :param mode: Deployment mode
         Values can be Incremental or complete (use: DeploymentMode.incremental or DeploymentMode.complete)
        :type mode: str
        :param template: Template file deserialized
        :type template: dict
        :param parameters: Parameters file deserialized
        :type parameters: dict
        :param resource_group_name: Resource group name to use in the deployment
        :type resource_group_name: str
        :param deployment_name: Deployment name to use
        :type deployment_name: str
        
        :return: Deployment output, if any, otherwise None is returned
        :rtype: dict
        :raises: :class:`Exception`
        """

        try:
            deployment_properties = {
                'mode': mode,
                'template': template,
                'parameters': parameters
            }

            deployment_async_operation = \
                self._resource_management_client\
                    .deployments\
                    .create_or_update(
                        resource_group_name,
                        deployment_name,
                        deployment_properties)

            # Wait for the resource provisioning to complete
            deployment_async_operation.wait()
            deployment_result = \
                deployment_async_operation.result()

            if deployment_result.properties is not None and \
               deployment_result.properties.outputs is not None:
                return deployment_result.properties.outputs
            else:
                return None

        except Exception as e:
            self._logger\
                .error('The following error occurred while checking executing a deployment: ' + str(e))
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)

    def validate_deployment(
        self, 
        mode: str, 
        template: dict, 
        parameters: dict,
        resource_group_name: str,
        deployment_name: str):
        """Function that validates whether a template is syntactically correct.

        :param mode: Deployment mode
         Values can be Incremental or complete (use: DeploymentMode.incremental or DeploymentMode.complete)
        :type mode: str
        :param template: Template file deserialized
        :type template: dict
        :param parameters: Parameters file deserialized
        :type parameters: dict
        :param resource_group_name: Resource group name to use in the deployment
        :type resource_group_name: str
        :param deployment_name: Deployment name to use
        :type deployment_name: str
        
        :return: Deployment output, if any, otherwise None is returned
        :rtype: dict
        :raises: :class:`Exception`
        """
        
        try:
            deployment_properties = {
                'mode': mode,
                'template': template,
                'parameters': parameters
            }
            
            validation_response = \
                self._resource_management_client\
                    .deployments\
                    .validate(
                        resource_group_name,
                        deployment_name,
                        deployment_properties)
            
            if validation_response.error is not None:
                inner_exception = 'None'

                if validation_response.error.details is not None and\
                    len(validation_response.error.details) > 0 and\
                    validation_response.error.details[0].message is not None:
                    inner_exception = validation_response.error.details[0].message

                if validation_response.error.details is not None and\
                 len(validation_response.error.details) > 0 and\
                 validation_response.error.details[0].details is not None and\
                 len(validation_response.error.details[0].details) > 0 and\
                 validation_response.error.details[0].details[0].message is not None:
                    inner_exception = validation_response.error.details[0].details[0].message

                raise CustomException("ERROR: {}, INNER EXCEPTION: {}".format(
                    validation_response.error, 
                    inner_exception))
            
            self._logger.info('Deployment successfully validated')

        except Exception as e:
            self._logger.error('The following error occurred while checking executing a deployment validation: ' + str(e))
            self._logger.error(e)
            self._logger.error(validation_response)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
    
    def resource_group_exists(
        self, 
        resource_group_name: str):
        """Function that evaluates if a resource group exists or not

        :param resource_group_name: Resource group name to analyze
        :type resource_group_name: str

        :return: exists value
        :rtype: bool
        :raises: :class:`Exception`
        """

        try:
            return self._resource_management_client\
                       .resource_groups.check_existence(
                            resource_group_name)
        except Exception as e:
            self._logger.error('The following error occurred while checking if a resource group exists: ' + str(e))
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)

    def create_or_update_resource_group(
        self, 
        resource_group_name: str, 
        location: str):
        """Function that creates or updates a resource group

        :param resource_group_name: Resource group name to analyze
        :type resource_group_name: str
        :param location: Resource group location
        :type location: str

        :raises: :class:`Exception`
        """

        if location is None or location == '':     
            raise CustomException('No location has been set')
        
        try:
            resource_group_parameters = \
                ResourceGroup(location = location)
        
            new_resource_group: ResourceGroup = \
                self._resource_management_client\
                    .resource_groups\
                    .create_or_update(
                        resource_group_name, 
                        resource_group_parameters)
        
            self._logger.info('resource group {} created on {} location'.format(
                new_resource_group.name, 
                new_resource_group.location))
        except Exception as e:
            self._logger.error('The following error occurred while creating a resource group: ' + str(e))
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
    
    def delete_resource_group(
        self, 
        resource_group_name: str):
        """Function that deletes a resource group

        :param resource_group_name: Resource group name to analyze
        :type resource_group_name: str

        :raises: :class:`Exception`
        """

        try:
            self._logger.debug('About to delete a resource group: {}'.format(
                resource_group_name))

            delete_async_operation = \
                self._resource_management_client\
                    .resource_groups.delete(
                        resource_group_name)
            delete_async_operation.wait()
            self._logger.info('resource group {} successfully deleted'.format(resource_group_name))
    
        except Exception as e:
            self._logger.error('The following error occurred while creating a resource group: ' + str(e))
            self._logger.error(e)
            sys.exit(1) # Exit the module as it is not possible to progress the deployment.
            raise(e)
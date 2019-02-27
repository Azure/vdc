from interface import Interface
from orchestration.common.parameter_initializer import ParameterInitializer
from orchestration.models.resource_module import ResourceModule

class BusinessInterface(Interface):

    def create(self) -> list:
        '''Main function used to execute a module(s) deployment.

        This function creates a storage repository to place all deployment outputs, and to to place
        custom scripts if --upload-scripts argument passed is set to true.
        :param parameter_initializer: Object containing all required properties used during a module provisioning
        :type parameter_initializer: ParameterInitializer
        :param deployment_path: Path that contains deployment and parameters folders
        :type deployment_path: str
        :return param resource_groups_provisioned: A list containing all
        the resource groups provisioned
        :return type list
        :raises: :class:`CustomException<Exception>`
        '''
        pass

    def create_vdc_storage(
        self):
        """Function that creates a vdc storage to store deployment outputs and custom scripts.

        :raises: :class:`Exception`
        """
        pass

    def get_deployment_template_contents(
        self,
        all_modules: list,
        module_name: str):
        """Function that reads a local folder to fetch a deployment template file.
        
        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name: Resource name used to construct the file path 
        (i.e. /modules/shared-services-net/v1/azureDeploy.json)
        :type module_name: str

        :raises: :class:`Exception`
        """
        pass

    def get_parameters_template_contents(
        self,
        all_modules: list,
        module_name: str):
        """Function that reads a local folder to fetch a deployment parameters file.
        
        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name: Resource name used to construct the file path 
        (i.e. modules/shared-services-net/v1/azureDeploy.parameters.json)
        :type module_name: str

        :raises: :class:`Exception`
        """
        pass

    def create_policies(
        self,
        all_modules: list,
        module_name: str=None,
        resource_group_name: str=None,
        is_subscription_policy: bool = False):
        """Function that creates and assigns policies.
        
        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name: Resource name used to construct the file path 
        (i.e. policies/shared-services/net/arm.policies.json)
        :type module_name: str
        :param resource_group_name: Resource group name used in the policy assignment. 
        This value is required when is_subscription_policy is set to True
        :type resource_group_name: str
        :param is_subscription_policy: Instructs the function to assign a policy to a subscription (true)
        or resource group (false)
        :type is_subscription_policy: bool

        :raises: :class:`CustomException`
        """
        pass

    def store_deployment_outputs(
        self,
        container_name: str,
        output_name: str,
        output_content_data: str):
        """Function that stores deployment outputs.

        :param container_name: The name of container where the outputs (in json format) will be placed.        
        :type container_name: str
        :param output_name: Name of the output file
        :type output_name: str
        :param output_content_data: Deployment output data (deserialized json)
        :type output_name: str
        
        :raises: :class:`Exception`
        """
        pass

    def store_custom_scripts(
        self):
        """Function that stores custom scripts (from scripts folder).

        :raises: :class:`Exception`
        """
        pass

    def find_module(
        self,
        all_modules: list,
        module_to_find: str) -> ResourceModule:
        """Function that returns a module from parameters/shared-services|workload/azureDeploy.parameters.json -> module-dependencies

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param all_modules: Array of dictionaries containing all module-dependencies
        :type all_modules: list
        :param module_to_find: Resource name to find in module-dependencies
        :type module_to_find: str
        
        :return: module or None  if no module was found
        :rtype: ResourceModule
        :raises: :class:`Exception`
        """
        pass

    def find_dependencies(
        self,
        all_modules: list,
        module_to_find: str) -> list:
        """Function that returns module dependencies, if any (parameters/shared-services|workload/azureDeploy.parameters.json -> module-dependencies -> dependencies)

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name_to_find: Resource name to analyze if dependencies property contains any values
        :type module_name_to_find: str
        
        :return: module dependencies or None if no values were found
        :rtype: dict
        :raises: :class:`Exception`
        """
        pass

    def append_dependency_parameters(
        self,
        all_modules: list,
        module_name: str):
        """Function that appends dependency parameters to parameters file. If a module contains
        dependencies (module-dependencies -> dependencies) and these dependencies generated an
        output, then these values get appended to the parameters file.
        This is similar to a linked template where the deployment contains 
        outputs [reference('<name-of-deployment>').outputs.<property-name>.value].

        This function also appends the values from _default_parameters. 
        By default there are three
        values:
         {
            'sas-key': sas_key, 
            'output-params-storage-key': storage_account_key, 
            'output-params-storage-account-name': self._vdc_storage_account_name
         }

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_name: Resource name used to construct the parameters file path        
        :type module_name: str
        :param template_file_contents: Template file deserialized
        :type template_file_contents: str
        
        :return: deployment parameters
        :rtype: dict
        :raises: :class:`Exception`
        """
        pass

    def is_a_dependency_deployable_in_dependent_rg(
        self, 
        all_modules: list,
        module_to_find: str) -> ResourceModule:
        """Function that evaluates if a module dependency will be deployed in a dependent resource group.
        If parameters/shared-services|workload/azureDeploy.parameters.json -> module-dependencies -> same-resource-group is set to true, it means
        that the dependencies will be deployed in the dependent resource group

        :param all_modules: List containing an array of all modules. 
         This array is retrieved from main parameters file -> module-dependencies -> modules array
        :type all_modules: list
        :param module_to_find: Resource to find in dependencies property
         parameters/shared-services|workload/azureDeploy.parameters.json -> module-dependencies -> dependencies
        :type module_to_find: str

        :raises: :class:`Exception`
        """
        pass

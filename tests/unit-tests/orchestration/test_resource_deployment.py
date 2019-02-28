from orchestration.resource_deployment import ResourceDeployment
from orchestration.models.resource_module import ResourceModule
from orchestration.common.module_version import ModuleVersionRetrieval
from orchestration.common.local_file_finder import LocalFileFinder
from orchestration.common.remote_file_finder import RemoteFileFinder
from orchestration.integration.sdk.resource_management_client import ResourceManagementClientSdk
from orchestration.integration.sdk.policy_client import PolicyClientSdk
from orchestration.data.blob_storage import BlobStorage
from orchestration.integration.cli.aad_client import AADClientCli
from orchestration.integration.cli.keyvault_client import KeyVaultClientCli
from unittest.mock import MagicMock
from orchestration.common.parameter_initializer import ParameterInitializer
import os.path
import unittest
import json

class ResourceDeploymentTests(unittest.TestCase):

    _resource_deployment: ResourceDeployment
    _args = dict({
        'resource-group': None,
        'module': '',
        'location': '',
        'configuration-path': 'SOME_PATH',
        'environment-type': 'shared-services',
        'deploy-module-dependencies': False,
        'service-principals': list(),
        'upload-scripts': False,
        'validate-deployment': False,
        'delete-validation-modules': True,
        'create-vdc-storage': False
    })

    _main_parameters = dict(
        {
            "general": {
                "organization-name": "contoso",
                "tenant-id": "00000000-0000-0000-0000-000000000000",
                "deployment-user-id": "00000000-0000-0000-0000-000000000000",
                "vdc-storage-account-name": "storage",
                "vdc-storage-account-rg": "vdc-storage-rg",
                "shared-services": {
                    "subscription-id": "00000000-0000-0000-0000-000000000000",
                    "deployment-name": "shared-services",
                    "region": "Central US",
                    "adds": {
                        "vm-ip-address-start": "10.4.0.46",
                        "adds-vm1-hostname": "adds-vm1",
                        "adds-vm2-hostname": "adds-vm2"
                    },
                    "active-directory": {
                        "discovery-custom-domain": "contosocloud.com",
                        "domain-admin-user": "contoso",
                        "domain-name": "contoso.com"
                    },
                    "network": {
                        "network-virtual-appliance": {
                            "egress-ip": "10.4.1.4",                    
                            "custom-ubuntu": {
                                "egress": {
                                    "ip": "10.4.0.20",
                                    "vm-ip-address-start": "10.4.0.5"
                                }
                            }
                        },
                        "application-security-group": {
                            "domain-controller-asg-name": "dc"
                        }
                    }
                }
            },
            "orchestration": {
                "modules-to-deploy":[
                    "la",
                    "nsg",
                    "net",
                    "vgw",
                    "vgw-connection",
                    "onprem-vgw-connection",
                    "azure-fw",
                    "kv",
                    "jb",
                    "adds"
                ],
                "module-validation-dependencies": [
                    "kv"
                ],
                "module-configuration": {
                    "import-modules": "file(sample-deployment/contoso-archetypes/shared-services)",
                    "custom-scripts": "file(scripts)",
                    "modules": [
                        {
                            "module": "net",
                            "resource-group-name": "${general.organization-name}-shared-services-net-rg",
                            "same-resource-group": True,
                            "source": {
                                "version": "1.0",
                                "template-path": "file()",
                                "parameters-path": "url()",
                                "policy-path": "file()"
                            },
                            "dependencies": [
                                "nsg"
                            ]
                        },
                        {
                            "module": "nsg",
                            "source": {
                                "version": "latest",
                                "template-path": "file(some-path/1.0)",
                                "parameters-path": "url()",
                                "policy-path": "file()"
                            },
                            "dependencies": [
                                "la"
                            ]
                        },
                        {
                            "module": "vgw",
                            "resource-group-name": "${general.organization-name}-shared-services-net-rg",
                            "source": {
                                "version": "1.0"
                            },
                            "dependencies": [
                                "net"
                            ]
                        },
                        {
                            "module": "vgw-connection",
                            "resource-group-name": "${general.organization-name}-${" + "ENV:ENVIRONMENT-TYPE}-net-rg",
                            "dependencies": [
                                "net",
                                "vgw"
                            ]
                        },
                        {
                            "module": "onprem-vgw-connection",
                            "resource-group-name": "${general.organization-name}-${" + "ENV:ENVIRONMENT-TYPE}-net-rg",
                            "dependencies": [
                                "net"
                            ]
                        },
                        {
                            "module": "azure-fw",
                            "resource-group-name": "${general.organization-name}-${" + "ENV:ENVIRONMENT-TYPE}-net-rg",
                            "dependencies": [
                                "net",
                                "la"
                            ]
                        },
                        {
                            "module": "kv",
                            "dependencies": [
                                "la"
                            ]
                        },
                        {
                            "module": "adds",
                            "dependencies": [
                                "kv",
                                "net",
                                "la"
                            ]
                        },
                        {
                            "module": "jb",
                            "dependencies": [
                                "kv",
                                "net",
                                "la"
                            ]
                        },
                        {
                            "module": "ubuntu-nva",
                            "dependencies": [
                                "kv",
                                "net"
                            ]
                        }
                    ]
                }
            },
            "on-premises":{
                "subscription-id": "00000000-0000-0000-0000-000000000000",
                "location": "Central US",
                "vnet-rg": "contoso-onprem-net-rg",
                "gateway-name": "contoso-onprem-gw",
                "address-range":"192.168.1.0/28",
                "primaryDC-IP": "192.168.1.4",
                "allow-rdp-address-range": "192.168.1.4",
                "AD-sitename": "Cloud-Site"
            },
            "shared-services":{  
                "subscription-id": "00000000-0000-0000-0000-000000000000",
                "deployment-name": "shared-services",
                "region": "Central US",
                "ancillary-region":"East US",
                "log-analytics-region": "West US 2",
                "gateway-type": "vpn",
                "gateway-sku": "VpnGw1",
                "vpn-type": "RouteBased",
                "enable-ddos-protection": False,
                "azure-firewall-private-ip": "10.4.1.4",
                "ubuntu-nva-lb-ip-address": "10.4.0.20",
                "ubuntu-nva-address-start": "10.4.0.5",
                "squid-nva-address-start": "10.4.0.5",
                "domain-admin-user": "contoso",
                "domain-name": "contoso.com",
                "local-admin-user": "admin-user",
                "adds-address-start": "10.4.0.46",
                "enable-encryption": False,
                "encryption-keys-for": []
            }
        })
    
    _parameter_initializer = ParameterInitializer()
    
    def setUp(self):
        deployment_path = 'SOME_PATH'
        
        self._parameter_initializer = ParameterInitializer()

        self._parameter_initializer._get_json_configuration_file = \
            MagicMock(return_value=self._main_parameters)
        
        self._parameter_initializer.initialize(
            args=self._args,
            deployment_configuration_path=deployment_path,
            is_live_mode=False)

        self._parameter_initializer\
            ._get_json_configuration_file\
            .assert_called_with(deployment_path)

        self._module_version_retrieval = \
                ModuleVersionRetrieval(
                    main_module = self._parameter_initializer._import_module,
                    local_file_finder = LocalFileFinder(),
                    remote_file_finder = RemoteFileFinder())

        self._module_version_retrieval.get_template_file = \
            MagicMock(return_value=dict())
        
        self._data_store = MagicMock()
        self._resource_management_integration_service = MagicMock()
        self._policy_integration_service = MagicMock()
        self._aad_cli_integration_service = MagicMock()
        self._keyvault_cli_integration_service = MagicMock()
    
        self._resource_deployment = \
            ResourceDeployment(
                self._data_store,
                self._resource_management_integration_service,
                self._policy_integration_service,
                self._aad_cli_integration_service,
                self._keyvault_cli_integration_service,
                self._module_version_retrieval,
                self._parameter_initializer._vdc_storage_account_name,
                self._parameter_initializer._vdc_storage_account_subscription_id,
                self._parameter_initializer._vdc_storage_account_resource_group,
                self._parameter_initializer._validate_deployment,
                self._parameter_initializer._deploy_all_modules,
                self._parameter_initializer._deployment_configuration_path,
                self._parameter_initializer._module_deployment_order,
                self._parameter_initializer._resource_group,
                self._parameter_initializer._single_module,
                self._parameter_initializer._deploy_module_dependencies,
                self._parameter_initializer._upload_scripts,
                self._parameter_initializer._create_vdc_storage,
                self._parameter_initializer._shared_services_deployment_name,
                self._parameter_initializer._deployment_name,
                self._parameter_initializer._location,
                self._parameter_initializer._tenant_id,
                self._parameter_initializer._subscription_id,
                self._parameter_initializer._shared_services_subscription_id,
                self._parameter_initializer._service_principals,
                self._parameter_initializer._organization_name,
                self._parameter_initializer._encryption_keys_for,
                self._parameter_initializer._module_dependencies,
                self._parameter_initializer._environment_type,
                self._parameter_initializer._json_parameters,
                self._parameter_initializer._import_module,
                self._parameter_initializer._custom_scripts_path,
                self._parameter_initializer._environment_keys)
                
    def test_find_module_that_exists(self):
        module_to_find = 'net'
        module_found = \
            self._resource_deployment.find_module(
                all_modules=self._parameter_initializer._module_dependencies, 
                module_to_find=module_to_find)
        
        self.assertEqual(module_found._module, module_to_find)

    def test_find_module_that_does_not_exists(self):
        module_to_find = 'ops'
        module_found = \
            self._resource_deployment.find_module(
                all_modules=self._parameter_initializer._module_dependencies, 
                module_to_find=module_to_find)

        self.assertIsNone(module_found)

    def test_is_a_dependency_deployable_in_dependent_rg_dependency_found(self):
        module_to_find = 'nsg'
        module_found = \
            self._resource_deployment\
                .is_a_dependency_deployable_in_dependent_rg(
                    all_modules=self._parameter_initializer._module_dependencies, 
                    module_to_find=module_to_find)
        
        self.assertEqual(module_found._module, 'net')

    def test_is_a_dependency_deployable_in_dependent_rg_dependency_not_found(self):
        module_dependency_to_find = 'nva'
        module_found = \
            self._resource_deployment\
                .is_a_dependency_deployable_in_dependent_rg(
                    all_modules=self._parameter_initializer._module_dependencies, 
                    module_to_find=module_dependency_to_find)
        
        self.assertIsNone(module_found)

    def test_find_dependencies_dependency_found(self):
        module_to_find = 'nsg'
        dependencies_found = \
            self._resource_deployment\
                .find_dependencies(
                    all_modules=self._parameter_initializer._module_dependencies, 
                    module_to_find=module_to_find)
        
        self.assertEqual(
            dependencies_found, 
            self._parameter_initializer._module_dependencies[1]['dependencies'])

    def test_find_dependencies_dependency_not_found(self):
        module_to_find = 'ops'
        dependencies_found = \
            self._resource_deployment\
                .find_dependencies(
                    all_modules=self._parameter_initializer._module_dependencies, 
                    module_to_find=module_to_find)
        
        self.assertIsNone(dependencies_found)

    def test_get_deployment_template_contents(self):
        
        module_to_find = 'nsg'
        
        self._resource_deployment\
            .get_deployment_template_contents(
                self._parameter_initializer._module_dependencies,
                module_to_find)

        self._module_version_retrieval.get_template_file.assert_called_with(
            version='latest',
            module_name='nsg',
            path='file(some-path/1.0)')

    def test_resource_deployment_with_no_dependencies(self):
        self._resource_deployment._create_vdc_storage = True
        self._resource_deployment.create_vdc_storage =\
            MagicMock()

        self._resource_deployment.store_custom_scripts =\
            MagicMock()

        self._resource_deployment.get_sas_key =\
            MagicMock(return_value="SAS_KEY")

        self._data_store.get_storage_account_key =\
            MagicMock(return_value="STORAGE_ACCOUNT_KEY")

        self._resource_deployment.create_policies =\
            MagicMock()

        self._deploy_module_dependencies = False
        self._resource_deployment._deploy_all_modules = False
        self._resource_deployment._single_module = 'la'
        self._resource_deployment._deploy =\
            MagicMock(return_value=['RESOURCE_GROUP_NAME'])

        resource_groups_created = \
            self._resource_deployment.create()

        self._resource_deployment\
            .create_vdc_storage\
            .assert_called_with()

        self.assertEqual(
            resource_groups_created, 
            ['RESOURCE_GROUP_NAME'])

        self.assertEqual(
            self._resource_deployment._default_parameters['sas-key'],
            {'value': 'SAS_KEY'})

        self.assertEqual(
            self._resource_deployment._default_parameters['output-params-storage-key'],
            {'value': 'STORAGE_ACCOUNT_KEY'})

        self.assertEqual(
            self._resource_deployment._default_parameters['output-params-storage-account-name'],
            {'value': 'storage'})
        

    def test_resource_deployment_with_single_dependency_and_deploy_dependencies_enabled(self):
        self._resource_deployment._create_vdc_storage = True
        self._resource_deployment.create_vdc_storage =\
            MagicMock()

        self._resource_deployment.store_custom_scripts =\
            MagicMock()

        self._resource_deployment.get_sas_key =\
            MagicMock(return_value="SAS_KEY")

        self._data_store.get_storage_account_key =\
            MagicMock(return_value="STORAGE_ACCOUNT_KEY")

        self._resource_deployment.create_policies =\
            MagicMock()

        self._resource_deployment._deploy_module_dependencies = True
        self._resource_deployment._deploy_all_modules = False
        self._resource_deployment._single_module = 'kv'
        
        self._resource_deployment._deploy_initial =\
            MagicMock()

        resource_groups_created = \
            self._resource_deployment.create()

        self.assertEqual(
            resource_groups_created, 
            ['contoso-shared-services-la-rg', 
             'contoso-shared-services-kv-rg'])

        self.assertEqual(
            self._resource_deployment._default_parameters['sas-key'],
            {'value': 'SAS_KEY'})

        self.assertEqual(
            self._resource_deployment._default_parameters['output-params-storage-key'],
            {'value': 'STORAGE_ACCOUNT_KEY'})

        self.assertEqual(
            self._resource_deployment._default_parameters['output-params-storage-account-name'],
            {'value': 'storage'})

    def test_resource_deployment_with_multiple_dependencies_and_deploy_dependencies_enabled(self):
        self._resource_deployment._create_vdc_storage = True
        self._resource_deployment.create_vdc_storage =\
            MagicMock()

        self._resource_deployment.store_custom_scripts =\
            MagicMock()

        self._resource_deployment.get_sas_key =\
            MagicMock(return_value="SAS_KEY")

        self._data_store.get_storage_account_key =\
            MagicMock(return_value="STORAGE_ACCOUNT_KEY")

        self._resource_deployment.create_policies =\
            MagicMock()

        self._resource_deployment._deploy_module_dependencies = True
        self._resource_deployment._deploy_all_modules = False
        self._resource_deployment._single_module = 'adds'
        
        self._resource_deployment._deploy_initial =\
            MagicMock()

        resource_groups_created = \
            self._resource_deployment.create()

        self.assertEqual(
            resource_groups_created, 
            ['contoso-shared-services-la-rg', 
             'contoso-shared-services-net-rg',
             'contoso-shared-services-kv-rg',
             'contoso-shared-services-adds-rg'])

        self.assertEqual(
            self._resource_deployment._default_parameters['sas-key'],
            {'value': 'SAS_KEY'})

        self.assertEqual(
            self._resource_deployment._default_parameters['output-params-storage-key'],
            {'value': 'STORAGE_ACCOUNT_KEY'})

        self.assertEqual(
            self._resource_deployment._default_parameters['output-params-storage-account-name'],
            {'value': 'storage'})

    def test_resource_deployment_with_single_dependency_and_deploy_dependencies_disabled(self):
        self._resource_deployment._create_vdc_storage = True
        self._resource_deployment.create_vdc_storage =\
            MagicMock()

        self._resource_deployment.store_custom_scripts =\
            MagicMock()

        self._resource_deployment.get_sas_key =\
            MagicMock(return_value="SAS_KEY")

        self._data_store.get_storage_account_key =\
            MagicMock(return_value="STORAGE_ACCOUNT_KEY")

        self._resource_deployment.create_policies =\
            MagicMock()

        self._resource_deployment._deploy_module_dependencies = False
        self._resource_deployment._deploy_all_modules = False
        self._resource_deployment._single_module = 'kv'
        
        self._resource_deployment._deploy_initial =\
            MagicMock()

        resource_groups_created = \
            self._resource_deployment.create()

        self.assertEqual(
            resource_groups_created, 
            ['contoso-shared-services-kv-rg'])

        self.assertEqual(
            self._resource_deployment._default_parameters['sas-key'],
            {'value': 'SAS_KEY'})

        self.assertEqual(
            self._resource_deployment._default_parameters['output-params-storage-key'],
            {'value': 'STORAGE_ACCOUNT_KEY'})

        self.assertEqual(
            self._resource_deployment._default_parameters['output-params-storage-account-name'],
            {'value': 'storage'})

    def test_resource_deployment_with_multiple_dependencies_and_deploy_dependencies_disabled(self):
        self._resource_deployment._create_vdc_storage = True
        self._resource_deployment.create_vdc_storage =\
            MagicMock()

        self._resource_deployment.store_custom_scripts =\
            MagicMock()

        self._resource_deployment.get_sas_key =\
            MagicMock(return_value="SAS_KEY")

        self._data_store.get_storage_account_key =\
            MagicMock(return_value="STORAGE_ACCOUNT_KEY")

        self._resource_deployment.create_policies =\
            MagicMock()

        self._resource_deployment._deploy_module_dependencies = False
        self._resource_deployment._deploy_all_modules = False
        self._resource_deployment._single_module = 'adds'
        
        self._resource_deployment._deploy_initial =\
            MagicMock()

        resource_groups_created = \
            self._resource_deployment.create()

        self.assertEqual(
            resource_groups_created, 
            ['contoso-shared-services-adds-rg'])

        self.assertEqual(
            self._resource_deployment._default_parameters['sas-key'],
            {'value': 'SAS_KEY'})

        self.assertEqual(
            self._resource_deployment._default_parameters['output-params-storage-key'],
            {'value': 'STORAGE_ACCOUNT_KEY'})

        self.assertEqual(
            self._resource_deployment._default_parameters['output-params-storage-account-name'],
            {'value': 'storage'})
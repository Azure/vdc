from orchestration.common.parameter_initializer import ParameterInitializer
from unittest.mock import MagicMock
import unittest

class ParameterInitializerTests(unittest.TestCase):

    _args = dict({
        'resource-group': '',
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
                "on-premises": {
                    "deployment-name": "onprem",
                    "subscription-id": "00000000-0000-0000-0000-000000000000",
                    "region": "Central US",
                    "active-directory": {
                        "AD-sitename": "Cloud-Site",
                        "domain-admin-user": "contoso",
                        "domain-name": "contoso.com"
                    }
                },
                "shared-services": {
                    "subscription-id": "00000000-0000-0000-0000-000000000000",
                    "deployment-name": "shared-services",
                    "region": "Central US"
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
                            "resource-group-name": "${general.organization-name}-shared-services-net-rg",
                            "source": {
                                "version": "latest",
                                "template-path": "file()",
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

    def test_class_initialize(self):
        
        deployment_path = 'SOME_PATH'
        
        parameter_initializer = ParameterInitializer()

        parameter_initializer._get_json_configuration_file = \
            MagicMock(return_value=self._main_parameters)
        
        parameter_initializer.initialize(
            args=self._args,
            deployment_configuration_path=deployment_path,
            is_live_mode=False)

        parameter_initializer._get_json_configuration_file.assert_called_with(
            deployment_path)

        self.assertEqual(
            parameter_initializer._shared_services_subscription_id, 
            '00000000-0000-0000-0000-000000000000')
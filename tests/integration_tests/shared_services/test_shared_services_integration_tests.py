from tools.devtools_testutils.base_replayable_test_case import VDCBaseTestCase
from tools.devtools_testutils.base_integration_test_case import BaseIntegrationTestCase
from pathlib import Path
from os.path import join
import unittest

args = dict()
args['resource-group'] = None
args['validate-deployment'] = None
args['deploy-module-dependencies'] = None
args['service-principals'] = None
args['create-vdc-storage'] = None
args['environment-type'] = 'shared-services'
args['upload-scripts'] = None
args['create-vdc-storage'] = None
args['delete-validation-modules'] = None

class AllResources(BaseIntegrationTestCase):
    
    def setUp(self):
        super(AllResources, self).setUp()

        parameters_file = ''

        if self.is_live:
            parameters_file = 'archetype.json'
        else:
            parameters_file = 'archetype.test.json'

        self._shared_services_path = join(
                Path(__file__).parents[3],
                'archetypes',
                'shared-services',
                parameters_file)
        self._environment_type = 'shared-services'

    def test_a_shared_services_log_analytics_creation(self):

        self.set_resource_to_deploy('la', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, True)
        successful: bool = self.execute_deployment_test(
            args,
            self._shared_services_path,
            self._environment_type)

        self.assertEqual(successful, True)
    
    def test_b_shared_services_nsg_creation(self):

        self.set_resource_to_deploy('nsg', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._shared_services_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_c_shared_services_network_creation(self):
        
        self.set_resource_to_deploy('shared-services-net', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._shared_services_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_d_shared_services_network_creation(self):
        
        self.set_resource_to_deploy('vgw', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._shared_services_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_e_shared_services_network_creation(self):
        
        self.set_resource_to_deploy('vgw-connection', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._shared_services_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_f_shared_services_network_creation(self):
        
        self.set_resource_to_deploy('onprem-vgw-connection', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._shared_services_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_g_shared_services_network_creation(self):
        
        self.set_resource_to_deploy('azure-fw', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._shared_services_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_h_shared_services_keyvault_creation(self):
        
        self.set_resource_to_deploy('kv', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._shared_services_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_i_shared_services_jumpbox_creation(self):
        
        self.set_resource_to_deploy('jb', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._shared_services_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_j_shared_services_adds_creation(self):
        
        self.set_resource_to_deploy('adds', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._shared_services_path,
            self._environment_type)

        self.assertEqual(successful, True)
    

#------------------------------------------------------------------------------
if __name__ == '__main__':
    unittest.main()
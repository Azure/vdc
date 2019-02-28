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
args['environment-type'] = 'on-premises'
args['upload-scripts'] = None
args['create-vdc-storage'] = None
args['delete-validation-modules'] = None

class SimulatedOnpremIntegrationTests(BaseIntegrationTestCase):
    
    def setUp(self):
        super(SimulatedOnpremIntegrationTests, self).setUp()

        parameters_file = ''

        if self.is_live:
            parameters_file = 'archetype.json'
        else:
            parameters_file = 'archetype.test.json'

        self._on_premises_path = join(
                Path(__file__).parents[3],
                'archetypes',
                'on-premises',
                parameters_file)
        self._environment_type = 'on-premises'
    
    def test_a_on_premises_nsg_creation(self):

        self.set_resource_to_deploy('nsg', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, True)
        
        successful: bool = self.execute_deployment_test(
            args,
            self._on_premises_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_b_on_premises_network_creation(self):
        
        self.set_resource_to_deploy('net', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._on_premises_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_c_on_premises_network_creation(self):
        
        self.set_resource_to_deploy('vgw', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._on_premises_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_d_on_premises_ad_creation(self):
        
        self.set_resource_to_deploy('ad', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._on_premises_path,
            self._environment_type)

        self.assertEqual(successful, True)

#------------------------------------------------------------------------------
if __name__ == '__main__':
    unittest.main()
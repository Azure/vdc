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
args['environment-type'] = 'workload'
args['upload-scripts'] = None
args['create-vdc-storage'] = None
args['delete-validation-modules'] = None

class SAPIntegrationTests(BaseIntegrationTestCase):
    
    def setUp(self):
        super(SAPIntegrationTests, self).setUp()

        parameters_file = ''

        if self.is_live:
            parameters_file = 'archetype.json'
        else:
            parameters_file = 'archetype.test.json'

        self._workload_path = join(
                Path(__file__).parents[3],
                'archetypes',
                'sap-hana',
                parameters_file)
        self._environment_type = 'workload'

    def test_a_workload_log_analytics_creation(self):

        self.set_resource_to_deploy('la', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, True)
        successful: bool = self.execute_deployment_test(
            args,
            self._workload_path,
            self._environment_type)

        self.assertEqual(successful, True)
    
    def test_b_workload_nsg_creation(self):

        self.set_resource_to_deploy('nsg', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._workload_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_c_workload_network_creation(self):
        
        self.set_resource_to_deploy('workload-net', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._workload_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_d_workload_kv_creation(self):
        
        self.set_resource_to_deploy('kv', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._workload_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_e_workload_iscsi_creation(self):
        
        self.set_resource_to_deploy('iscsi', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._workload_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_f_workload_nfs_creation(self):
        
        self.set_resource_to_deploy('nfs', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._workload_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_g_workload_hana_creation(self):
        
        self.set_resource_to_deploy('hana', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._workload_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_h_workload_ascs_creation(self):
        
        self.set_resource_to_deploy('ascs', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._workload_path,
            self._environment_type)

        self.assertEqual(successful, True)

    def test_i_workload_netweaver_creation(self):
        
        self.set_resource_to_deploy('netweaver', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._workload_path,
            self._environment_type)

        self.assertEqual(successful, True)

#------------------------------------------------------------------------------
if __name__ == '__main__':
    unittest.main()
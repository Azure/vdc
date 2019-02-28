# Integration testing

The VDC automation toolkit includes an integration testing feature that allows you to test your deployments against simulated HTTP responses from the Azure platform. This enables you to quickly verify that your deployment templates and parameter files will work before checking them into your source code repository.  

This integration testing feature is built using the [Azure SDK for Python's test functionality](https://github.com/Azure/azure-sdk-for-python/wiki/Contributing-to-the-tests). This functionality allows you to make a baseline recording of responses from the Azure platform using a known good version of your deployment. These recordings can then be "played back" during simulated deployments to quickly test you latest code.

## Prerequisites

Before using the toolkit's integration testing functionality, you will need to make sure several types of files are in place and properly configured.

### Dependency Modules Installation

Install the dependency modules / packages if you are running the tests outside the docker container. 

Start the dependency installation by navigating to the toolkit root folder in a terminal or command-line interface and running the following command 
```
pip install -r requirements.txt
```

### Test deployment parameters files

Each of the sample deployments contains a top level *archetype.test.json* test file that is used during integration testing. This file contains placeholders for a number of important fields used during deployments such subscription IDs or user names, and is used as the basis for the actual *archetype.json* you will have created to use in your actual deployments.

For integration testing to work, these test files should only be modified to include new parameter fields you may have added to your real top-level deployment parameters file as you've extended or modified a deployment. 

Test parameter files are expected to be included in your code repository, so should continue to use placeholder values consistent with existing values. They should never contain sensitive information such as real subscriptions, tenant, or user accounts.

### Integration testing configuration files

The integration testing functionality also depends on two files that are not included in the VDC automation toolkit code repository:

- tools/devtools_testutils/testsettings_local.cfg
- tools/devtools_testutils/vdc_settings_real.py

Both need to exist in the toolkit's *tools/devtools_testutils* folder. These files are listed in the toolkit's .gitignore file to prevent their inclusion in your repository by default, so you will need to create and configure these files before running any tests.

**testsettings_local.cfg**

The *testsettings_local.cfg* file consists of a single *live-mode* parameter which tells the testing functionality if it should be running in playback mode (offline testing mode) or recording mode (where an actual deployment is used to record data for offline testing). If this file is absent this *live-mode* value will default to false.

The content of this file should be a single line:
```
live-mode: false
```

**vdc_settings_real.py**
*tools/devtools_testutils/fake_settings.py*, which is included in the VDC automation toolkit, contains the placeholder values used by for tests running in playback mode. The *vdc_settings_real.py* file contains the actual subscription, AAD tenant, and credentials you will use when in recording mode. If you do not create this real file, you will only be able to run offline tests using pre-recorded data.
To set up this file create a blank *vdc_settings_real.py* in the  devtools_testutils folder, then copy the contents of *fake_settings.py* into it. Next you will need to update the real file by modifying the following variables:

| Variable name           | Description                                                | Placeholder value                            |
|-------------------------|------------------------------------------------------------|----------------------------------------------|
| ONPREM_SUBSCRIPTION_ID  | Subscription ID of your simulated on-premises environment. | 00000000-0000-0000-0000-000000000000         |
| SHARED_SERVICES_SUBSCRIPTION_ID     | Subscription ID of your shared services deployment.                    | 00000000-0000-0000-0000-000000000000         |
| WORKLOAD_SUBSCRIPTION_ID   | Subscription ID of your workload deployment.                  | 00000000-0000-0000-0000-000000000000         |
| AD_DOMAIN               | Domain used by for your AD tenant.                         | myaddomain.onmicrosoft.com                   |
| TENANT_ID               | ID of your Azure AD Tenant.                                | 00000000-0000-0000-0000-000000000000         |
| CLIENT_OID              | Object ID of the Azure AD user that will be assigned as the key vault service principle during your deployments. | 00000000-0000-0000-0000-000000000000         |


In addition to these values you will need to update the real file's *get_credentials* function to replace the fake basic authentication token using either the *ServicePrincipalCredentials* or *UserPassCredentials*. Both methods are included but commented out in the fake version of the file. 

For more information on how to set up these credentials see the [Getting Azure Credentials](https://github.com/Azure/azure-sdk-for-python/wiki/Contributing-to-the-tests#getting-azure-credentials) section of the Azure SDK for Python documentation.

## Sample tests

Each test should have a sub-folder in the [*tests/integration_tests*](../tests/integration_tests) folder. Each of these test sub-folders contains *test_all_resources.py* file which specifies what resources should be included as part of the test. Each test sub-folder also contain a *recordings* folder that contains the pre-recorded HTTP response data used for offline testing.

The toolkit includes pre-configured tests and recorded data for each of the sample deployments:
 
| Test folder | Sample deployment |
|-------------|-------------------|
| [tests/integration_tests/simulated_onprem](../tests/integration_tests/simulated_onprem) | [Simulated on-premises environment](06-deploying-the-simulated-on-premises-environment.md) |
| [tests/integration_tests/shared_services](../tests/integration_tests/shared_services) | [Sample VDC Shared services and central IT infrastructure](07-deploying-the-sample-vdc-shared-services.md) |
| [tests/integration_tests/paas_workload](../tests/integration_tests/paas_workload) | [Workload example 1: PaaS N-tier architecture](08-deploying-workloads-example1-paas-n-tier-architecture.md) |
| [tests/integration_tests/iaas_workload](../tests/integration_tests/iaas_workload) | [Workload example 2: IaaS N-tier architecture](08-deploying-workloads-example2-iaas-n-tier-architecture.md) |
| [tests/integration_tests/cloudbreak-workload](../tests/integration_tests/cloudbreak-workload) | [Workload example 3: Hadoop deployment](08-deploying-workloads-example3-hadoop-deployment.md) |
| [tests/integration_tests/sap_workload](../tests/integration_tests/sap_workload) | [Workload example 4: SAP HANA deployment](08-deploying-workloads-example4-sap-hana-deployment.md) |


## Running tests in offline mode

Before running offline (playback mode) tests, make sure your *testsettings_local.cfg* file has the *live-mode* parameter set to *false*.

Integration tests use [pytest](https://docs.pytest.org/en/latest/) test runner python module. Start a test by navigating to the toolkit root folder in a terminal or command-line interface and running the following command :

[Linux/OSX]

>   *python3 -m pytest tests/integration_tests/{deployment test folder}/{test file name}.py*

[Windows]

>   *py -m pytest tests/integration_tests/{deployment test folder}/{test file name}.py*

[Docker]

>   *python -m pytest tests/integration_tests/{deployment test folder}/{test file name}.py*

An offline test should take less than 30 seconds to complete.

## Recording test output

Running a test in online (recording mode) will deploy all resources defined in the relevant *test_all_resources.py* file. This deployment process will use the subscription, tenant, and user information stored in your *vdc_settings_real.py* .  Other settings will be pulled from the deployment's *archetype.test.json* file.

The test will record all HTTP traffic to and from the Azure Resource Manager APIs during this deployment and update the data in recordings folder for later use in offline testing. Make sure your online deployment completely succeeds before checking in recording files to your code repository.

To set the integration testing to online mode, update your *testsettings_local.cfg* file's *live-mode* parameter to *false*. Then start the deployment by navigating to the toolkit root folder in a terminal or command-line interface and running the following command (same command used for offline mode):

[Linux/OSX]

>   *python3 -m pytest tests/integration_tests/{deployment test folder}/{test file name}.py*

[Windows]

>   *py -m pytest tests/integration_tests/{deployment test folder}/{test file name}.py*

[Docker]

>   *python -m pytest tests/integration_tests/{deployment test folder}/{test file name}.py*

Online mode can take a long time as it will provision all of the resources for a deployment.

## Customizing integration tests

Using the existing sample tests as a base you should be able to easily modify these tests or create your own custom tests for new deployments.

### Create a new test  

To create a test for a new deployment, create a new folder in *tests/integration_tests/*. Copy one of the existing *test_all_resources.py* files into this new folder. 

This file's *setUp* function has a _workload_configuration_path variable (alternatively *_shared_services_configuration_path* or *_on_premises
_configuration_path* depending on the deployment type) that will need to point to the root folder of your deployment (the same path you point to when running the main vdc.py script). You will also need to configure the *_environment_type* variables that need to be configured

```python
    def setUp(self):
        super(AllResourcesUsing, self).setUp()
        parameters_file = ''

        if self.is_live:
            parameters_file = 'archetype.json'
        else:
            parameters_file = 'archetype.test.json'
        
        self._workload_path = join(
                Path(__file__).parents[3],
                'archetypes',
                '{new deployment folder name}',
                parameters_file)
        self._environment_type = 'workload'
```

### Adding a resource deployment to a test

Inside the *test_all_resources.py* file, including a resource deployment in a test is done by adding a function that will in turn call *VDCBaseTestCase* class' *execute_deployment_test* function for the resource deployment when the test is executed. 

Each deployment test should always include these functions for the *ops*, *kv*, *nsg*, and *net* resource deployments. Additional resource deployments should be added using this standardized format:

```python
    def test_x_workload_{resource deployment name}_creation(self):

        self.set_resource_to_deploy('{resource deployment name}', args)
        self.upload_scripts(args, False)
        self.create_vdc_storage(args, False)
        successful: bool = self.execute_deployment_test(
            args,
            self._workload_path,
            self._environment_type)

        self.assertEqual(successful, True)
```

from collections import namedtuple
import inspect
import os.path
import zlib
from azure_devtools.scenario_tests import (
    ReplayableTest, AzureTestError,
    AbstractPreparer, GeneralNameReplacer,
    OAuthRequestResponsesFilter, DeploymentNameReplacer,
    RequestUrlNormalizer,
    LargeRequestBodyProcessor,
    RecordingProcessor
)

from .config import TEST_SETTING_FILENAME
from . import fake_settings as fake_settings

class HttpStatusCode(object):
    OK = 200
    Created = 201
    Accepted = 202
    NoContent = 204
    NotFound = 404


def get_resource_name(name_prefix, identifier):
    # Append a suffix to the name, based on the fully qualified test name
    # We use a checksum of the test name so that each test gets different
    # resource names, but each test will get the same name on repeat runs,
    # which is needed for playback.
    # Most resource names have a length limit, so we use a crc32
    checksum = zlib.adler32(identifier) & 0xffffffff
    name = '{}{}'.format(name_prefix, hex(checksum)[2:]).rstrip('L')
    if name.endswith('L'):
        name = name[:-1]
    return name

def get_qualified_method_name(obj, method_name):
    # example of qualified test name:
    # test_mgmt_network.test_public_ip_addresses
    _, filename = os.path.split(inspect.getsourcefile(type(obj)))
    module_name, _ = os.path.splitext(filename)
    return '{0}.{1}'.format(module_name, method_name)

class VDCBaseTestCase(ReplayableTest):
    def __init__(self, method_name, config_file=None,
                 recording_dir=None, recording_name=None,
                 recording_processors=None, replay_processors=None,
                 recording_patches=None, replay_patches=None):
        self.working_folder = os.path.dirname(__file__)
        self.qualified_test_name = get_qualified_method_name(self, method_name)
        self._fake_settings, self._real_settings = self._load_settings()
        self.region = 'westus'
        self.scrubber = VDCGeneralNameReplacer()
        config_file = config_file or os.path.join(self.working_folder, TEST_SETTING_FILENAME)
        if not os.path.exists(config_file):
            config_file = None
        super(VDCBaseTestCase, self).__init__(
            method_name,
            config_file=config_file,
            recording_dir=recording_dir,
            recording_name=recording_name or self.qualified_test_name,
            recording_processors=recording_processors or self._get_recording_processors(),
            replay_processors=replay_processors or self._get_replay_processors(),
            recording_patches=recording_patches,
            replay_patches=replay_patches,
        )

    @property
    def settings(self):
        if self.is_live:
            if self._real_settings:
                return self._real_settings
            else:
                raise AzureTestError('Need a vdc_settings_real.py file to run tests live.')
        else:            
            return self._fake_settings

    def _load_settings(self):
        try:
            from . import vdc_settings_real as real_settings
            return fake_settings, real_settings
        except ImportError:
            return fake_settings, None

    def _get_recording_processors(self):
        return [
            self.scrubber,
            OAuthRequestResponsesFilter(),
            LargeRequestBodyProcessor(max_request_body=10),
            # DeploymentNameReplacer(), Not use this one, give me full control on deployment name
            RequestUrlNormalizer()
        ]

    def _get_replay_processors(self):
        return [
            RequestUrlNormalizer()
        ]

    def is_playback(self):
        return not self.is_live

    def _setup_scrubber(self):
        constants_to_scrub = [
            'ONPREM_SUBSCRIPTION_ID', 
            'ONPREM_DEPLOYMENT_NAME',
            'SHARED_SERVICES_SUBSCRIPTION_ID', 
            'SHARED_SERVICES_DEPLOYMENT_NAME',
            'WORKLOAD_SUBSCRIPTION_ID', 
            'WORKLOAD_DEPLOYMENT_NAME',
            'ORGANIZATION_NAME',
            'AD_DOMAIN', 
            'TENANT_ID', 
            'CLIENT_OID', 
            'ADLA_JOB_ID',
            'STORAGE_ACCOUNT_NAME']
            
        for key in constants_to_scrub:
            if hasattr(self.settings, key) and hasattr(self._fake_settings, key):
                self.scrubber.register_name_pair(getattr(self.settings, key),
                                                 getattr(self._fake_settings, key))

    def setUp(self):
        # Every test uses a different resource group name calculated from its
        # qualified test name.
        #
        # When running all tests serially, this allows us to delete
        # the resource group in teardown without waiting for the delete to
        # complete. The next test in line will use a different resource group,
        # so it won't have any trouble creating its resource group even if the
        # previous test resource group hasn't finished deleting.
        #
        # When running tests individually, if you try to run the same test
        # multiple times in a row, it's possible that the delete in the previous
        # teardown hasn't completed yet (because we don't wait), and that
        # would make resource group creation fail.
        # To avoid that, we also delete the resource group in the
        # setup, and we wait for that delete to complete.
        self._setup_scrubber()
        super(VDCBaseTestCase, self).setUp()

    def tearDown(self):
        return super(VDCBaseTestCase, self).tearDown()


class VDCGeneralNameReplacer(RecordingProcessor):
    
    def __init__(self):
        self.names_name = []

    def register_name_pair(self, old, new):
        self.names_name.append((old, new))

    def process_request(self, request):
        for old, new in self.names_name:
            request.uri = request.uri.replace(old, new)

            if self.is_text_payload(request) and request.body:
                body = str(request.body)
                if old in body:
                    request.body = body.replace(old, new)

        return request

    def process_response(self, response):
        for old, new in self.names_name:
            
            # Added is_bytes_payload function to obfuscate subscription information when 
            # uploading blobs (octect-stream)
            if self.is_bytes_payload(response) and response['body']['string']:
                response['body']['string'] = \
                    response['body']['string'].replace(bytes(old, 'utf8'), bytes(new, 'utf8'))
            elif self.is_text_payload(response) and response['body']['string']:
                response['body']['string'] = response['body']['string'].replace(old, new)

            self.replace_header(response, 'location', old, new)
            self.replace_header(response, 'azure-asyncoperation', old, new)

        return response

    def is_text_payload(self, entity):
        text_content_list = [
            'application/json', 
            'application/xml', 
            'text/', 
            'application/test-content']

        content_type = self._get_content_type(entity)
        if content_type:
            return any(content_type.startswith(x) for x in text_content_list)
        return True

    def is_bytes_payload(self, entity):
        text_content_list = ['application/octet-stream']

        content_type = self._get_content_type(entity)
        if content_type:
            return any(content_type.startswith(x) for x in text_content_list)
        return True

    def _get_content_type(self, entity):
        # 'headers' is a field of 'request', but it is a dict-key in 'response'
        headers = getattr(entity, 'headers', None)
        if headers is None:
            headers = entity.get('headers')

        content_type = None
        if headers:
            content_type = headers.get('content-type', None)
            if content_type:
                # content-type could an array from response, let us extract it out
                content_type = content_type[0] if isinstance(content_type, list) else content_type
                content_type = content_type.split(";")[0].lower()
        return content_type
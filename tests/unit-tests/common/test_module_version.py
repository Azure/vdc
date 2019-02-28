from orchestration.common.module_version import ModuleVersionRetrieval
from orchestration.common.ifile_finder import FileFinderInterface 
from orchestration.common.local_file_finder import LocalFileFinder
from orchestration.common.remote_file_finder import RemoteFileFinder
from unittest.mock import MagicMock
from os.path import join
import unittest
import json
import os
import sys

class ModuleVersionTests(unittest.TestCase):
    _template_parameters = dict({
            'par1': 'val1',
            'par2': 'val2'
        })
    
    _is_windows_os: bool = False

    if sys.platform == "win32":
        _is_windows_os = True

    def setUp(self):
        self._local_file_finder = LocalFileFinder()
        self._remote_file_finder = RemoteFileFinder()
        
        if self._is_windows_os:
            self._local_relative_main_module = 'main-deployment-module\\shared-services'
        else:
            self._local_relative_main_module = 'main-deployment-module/hushared-servicesb'

        self._local_absolute_main_module = \
            os.path.abspath(self._local_relative_main_module)
        
        self._local_relative_main_module_using_function = \
            'file({})'.format(self._local_relative_main_module)
        
    def test_initialize_class_with_local_path_using_function_and_relative_path(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)

        self.assertEqual(
            module_version._main_module, 
            self._local_absolute_main_module)

    def test_initialize_class_with_local_path_using_function_and_absolute_path(self):

        absolute_path = \
            "file({})".format(self._local_absolute_main_module)

        module_version = ModuleVersionRetrieval(
            absolute_path, 
            self._local_file_finder, 
            self._remote_file_finder)

        self.assertEqual(
            module_version._main_module, 
            self._local_absolute_main_module)

    def test_initialize_class_with_remote_path(self):

        remote_uri = 'http://contoso.com/main-deployment-module/shared-services'
        module_version = ModuleVersionRetrieval(
            'url({})'.format(remote_uri), 
            self._local_file_finder, 
            self._remote_file_finder)

        self.assertEqual(module_version._main_module, remote_uri)

    def test_initialize_class_with_two_functions_expected_valueError(self):
        
        with self.assertRaises(ValueError) as excinfo:        
            ModuleVersionRetrieval(
                'file() url(http://contoso.com/main-deployment-module/shared-services)', 
                self._local_file_finder, 
                self._remote_file_finder)

        self.assertEqual(excinfo.expected, ValueError)
        self.assertEqual(str(excinfo.exception), 'Invalid function received. Valid functions: file() or uri()')

    def test_initialize_class_with_unknown_function_expected_valueError(self):
        
        with self.assertRaises(ValueError) as excinfo:        
            ModuleVersionRetrieval(
                'filess(http://contoso.com/main-deployment-module/shared-services)', 
                self._local_file_finder, 
                self._remote_file_finder)

        self.assertEqual(excinfo.expected, ValueError)
        self.assertEqual(str(excinfo.exception), 'Invalid function received. Valid functions: file() or uri()')
    
    def test_initialize_class_with_invalid_local_path_expected_valueError(self):
        
        main_module = join('some-folder','some-file')

        with self.assertRaises(ValueError) as excinfo:        
            ModuleVersionRetrieval(
                main_module, 
                self._local_file_finder, 
                self._remote_file_finder)

        self.assertEqual(excinfo.expected, ValueError)
        self.assertEqual(str(excinfo.exception), 'Invalid main module path. Allowed values are local path (dir must exist) or URL. Received: {}'.format(main_module))

    def test_initialize_class_with_invalid_url_expected_valueError(self):
        
        main_module = 'contoso.com/main-deployment-module/shared-services'
        with self.assertRaises(ValueError) as excinfo:        
            ModuleVersionRetrieval(
                main_module, 
                self._local_file_finder, 
                self._remote_file_finder)

        self.assertEqual(excinfo.expected, ValueError)
        self.assertEqual(str(excinfo.exception), 'Invalid main module path. Allowed values are local path (dir must exist) or URL. Received: {}'.format(main_module))
   
    def test_get_latest_local_module_version(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function,
            self._local_file_finder, 
            self._remote_file_finder)
        
        module_name = 'net'
        
        module_version._get_all_local_version_folders =\
            MagicMock(return_value=['8.0', '4.0', '3.0', '2.0', '1.0'])
        
        latest_version =\
            module_version.get_latest_local_module_version(module_name)

        module_version\
            ._get_all_local_version_folders\
            .assert_called_with(module_name)

        self.assertEqual('8.0', latest_version)

    def test_get_template_file_using_local_main_path_with_function_including_module_and_version_is_none(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')

        module_version.get_latest_local_module_version =\
            MagicMock(return_value=latest_version)
        
        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file=\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version=None,
            module_name=module_name)

        module_version.get_latest_local_module_version.assert_called_with(
            module_name)

        self._local_file_finder.append_folders.assert_called_with(
            main_module,
            module_name,
            latest_version,
            'azureDeploy.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)
        
        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_local_main_path_with_function_including_module_and_version_is_latest(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')
        
        module_version.get_latest_local_module_version =\
            MagicMock(return_value=latest_version)
        
        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file=\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version='latest',
            module_name=module_name)

        module_version.get_latest_local_module_version.assert_called_with(
            module_name)

        self._local_file_finder.append_folders.assert_called_with(
            main_module,
            module_name,
            latest_version,
            'azureDeploy.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)
        
        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_local_main_path_with_function_including_module_and_fixed_version(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')

        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file=\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version=latest_version,
            module_name=module_name)

        self._local_file_finder.append_folders.assert_called_with(
            main_module,
            module_name,
            latest_version,
            'azureDeploy.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)
        
        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_local_absolute_path_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(absolute_path_with_file_name))
        
        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_local_absolute_path_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=absolute_path_with_file_name)

        self._local_file_finder.can_parse_path.assert_called_with(
            absolute_path_with_file_name)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_local_absolute_path_no_filename_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')
        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(absolute_path))
        
        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_local_absolute_path_no_filename_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)
        
        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=absolute_path)
        
        self._local_file_finder.can_parse_path.assert_called_with(
            absolute_path)

        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_local_relative_path_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)

        relative_path_with_file_name = join(
            relative_path,
            'azureDeploy.json')

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(relative_path_with_file_name))

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_local_relative_path_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)

        relative_path_with_file_name = join(
            relative_path,
            'azureDeploy.json')

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=relative_path_with_file_name)

        self._local_file_finder.can_parse_path.assert_called_with(
            relative_path_with_file_name)

        self._local_file_finder.can_parse_path.assert_called_with(
            relative_path_with_file_name)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_local_relative_path_no_filename_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)

        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)

        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(relative_path))

        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.append_folders.assert_called_with(
            absolute_path,
            'azureDeploy.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_local_relative_path_no_filename_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)
        
        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)

        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_template_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=relative_path)
        
        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.can_parse_path.assert_called_with(
            relative_path)

        self._local_file_finder.append_folders.assert_called_with(
            absolute_path,
            'azureDeploy.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_template_file_using_invalid_local_path_without_function_expected_valueError(self):
        
        with self.assertRaises(ValueError) as excinfo:        
            module_version = ModuleVersionRetrieval(
                self._local_relative_main_module_using_function, 
                self._local_file_finder, 
                self._remote_file_finder)
        
            relative_path = join(
                'SOME',
                'FOLDER',
                'THAT',
                'DOES NOT',
                'EXISTS')

            module_version.get_template_file(
                version='NOT CONSIDERED',
                module_name='NOT CONSIDERED',
                path=relative_path)

        self.assertEqual(excinfo.expected, ValueError)
        self.assertEqual(
            str(excinfo.exception), 
            'Invalid path. Allowed values are local path (file or dir must exist) or URL. Received: {}'.format(
                relative_path))

    def test_get_template_file_using_invalid_local_path_with_function_expected_valueError(self):
        
        with self.assertRaises(ValueError) as excinfo:        
            module_version = ModuleVersionRetrieval(
                self._local_relative_main_module_using_function, 
                self._local_file_finder, 
                self._remote_file_finder)
        
            relative_path = join(
                'SOME',
                'FOLDER',
                'THAT',
                'DOES NOT',
                'EXISTS')

            self._local_file_finder.is_directory =\
                MagicMock(return_value=True)

            module_version.get_template_file(
                version='NOT CONSIDERED',
                module_name='NOT CONSIDERED',
                path='file({})'.format(relative_path))
        
        absolute_path = os.path.abspath(relative_path)
        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)
        self.assertEqual(excinfo.expected, ValueError)

        if self._is_windows_os:
            self.assertEqual(
            str(excinfo.exception), 
            'File not found, path searched: {}\\azureDeploy.json'.format(
                absolute_path))
        else:
            self.assertEqual(
            str(excinfo.exception), 
            'File not found, path searched: {}/azureDeploy.json'.format(
                absolute_path))

    def test_get_parameters_file_using_local_main_path_with_function_including_module_and_version_is_none(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')

        module_version.get_latest_local_module_version =\
            MagicMock(return_value=latest_version)
        
        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file=\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version=None,
            module_name=module_name)

        module_version.get_latest_local_module_version.assert_called_with(
            module_name)

        self._local_file_finder.append_folders.assert_called_with(
            main_module,
            module_name,
            latest_version,
            'azureDeploy.parameters.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)
        
        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_local_main_path_with_function_including_module_and_version_is_latest(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')
        
        module_version.get_latest_local_module_version =\
            MagicMock(return_value=latest_version)
        
        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file=\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version='latest',
            module_name=module_name)

        module_version.get_latest_local_module_version.assert_called_with(
            module_name)

        self._local_file_finder.append_folders.assert_called_with(
            main_module,
            module_name,
            latest_version,
            'azureDeploy.parameters.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)
        
        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_local_main_path_with_function_including_module_and_fixed_version(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')

        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file=\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version=latest_version,
            module_name=module_name)

        self._local_file_finder.append_folders.assert_called_with(
            main_module,
            module_name,
            latest_version,
            'azureDeploy.parameters.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)
        
        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_local_absolute_path_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(absolute_path_with_file_name))
        
        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_local_absolute_path_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=absolute_path_with_file_name)

        self._local_file_finder.can_parse_path.assert_called_with(
            absolute_path_with_file_name)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_local_absolute_path_no_filename_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')
        
        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(absolute_path))
        
        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_local_absolute_path_no_filename_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)
        
        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=absolute_path)
        
        self._local_file_finder.can_parse_path.assert_called_with(
            absolute_path)
        
        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_local_relative_path_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)

        relative_path_with_file_name = join(
            relative_path,
            'azureDeploy.parameters.json')

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(relative_path_with_file_name))

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_local_relative_path_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)

        relative_path_with_file_name = join(
            relative_path,
            'azureDeploy.parameters.json')

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=relative_path_with_file_name)

        self._local_file_finder.can_parse_path.assert_called_with(
            relative_path_with_file_name)

        self._local_file_finder.can_parse_path.assert_called_with(
            relative_path_with_file_name)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_local_relative_path_no_filename_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)
        
        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)

        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(relative_path))
        
        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.append_folders.assert_called_with(
            absolute_path,
            'azureDeploy.parameters.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_local_relative_path_no_filename_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'azureDeploy.parameters.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)
        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)
        
        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_parameters_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=relative_path)
        
        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.can_parse_path.assert_called_with(
            relative_path)

        self._local_file_finder.append_folders.assert_called_with(
            absolute_path,
            'azureDeploy.parameters.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_parameters_file_using_invalid_local_path_without_function_expected_valueError(self):
        
        with self.assertRaises(ValueError) as excinfo:        
            module_version = ModuleVersionRetrieval(
                self._local_relative_main_module_using_function, 
                self._local_file_finder, 
                self._remote_file_finder)
        
            relative_path = join(
                'SOME',
                'FOLDER',
                'THAT',
                'DOES NOT',
                'EXISTS')

            module_version.get_parameters_file(
                version='NOT CONSIDERED',
                module_name='NOT CONSIDERED',
                path=relative_path)

        self.assertEqual(excinfo.expected, ValueError)
        self.assertEqual(
            str(excinfo.exception), 
            'Invalid path. Allowed values are local path (file or dir must exist) or URL. Received: {}'.format(
                relative_path))

    def test_get_parameters_file_using_invalid_local_path_with_function_expected_valueError(self):
        with self.assertRaises(ValueError) as excinfo:        
            module_version = ModuleVersionRetrieval(
                self._local_relative_main_module_using_function, 
                self._local_file_finder, 
                self._remote_file_finder)
        
            relative_path = join(
                'SOME',
                'FOLDER',
                'THAT',
                'DOES NOT',
                'EXISTS')
            
            self._local_file_finder.is_directory =\
                MagicMock(return_value=True)
            
            module_version.get_parameters_file(
                version='NOT CONSIDERED',
                module_name='NOT CONSIDERED',
                path='file({})'.format(relative_path))
        
        absolute_path = os.path.abspath(relative_path)
        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)
        self.assertEqual(excinfo.expected, ValueError)

        if self._is_windows_os:
            self.assertEqual(
                str(excinfo.exception), 
                'File not found, path searched: {}\\azureDeploy.parameters.json'.format(
                    absolute_path))
        else:
            self.assertEqual(
                str(excinfo.exception), 
                'File not found, path searched: {}/azureDeploy.parameters.json'.format(
                    absolute_path))

    def test_get_policy_file_using_local_main_path_with_function_including_module_and_version_is_none(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')

        module_version.get_latest_local_module_version =\
            MagicMock(return_value=latest_version)
        
        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file=\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version=None,
            module_name=module_name)

        module_version.get_latest_local_module_version.assert_called_with(
            module_name)

        self._local_file_finder.append_folders.assert_called_with(
            main_module,
            module_name,
            latest_version,
            'arm.policies.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)
        
        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_local_main_path_with_function_including_module_and_version_is_latest(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')
        
        module_version.get_latest_local_module_version =\
            MagicMock(return_value=latest_version)
        
        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file=\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version='latest',
            module_name=module_name)

        module_version.get_latest_local_module_version.assert_called_with(
            module_name)

        self._local_file_finder.append_folders.assert_called_with(
            main_module,
            module_name,
            latest_version,
            'arm.policies.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)
        
        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_local_main_path_with_function_including_module_and_fixed_version(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')

        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file=\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version=latest_version,
            module_name=module_name)

        self._local_file_finder.append_folders.assert_called_with(
            main_module,
            module_name,
            latest_version,
            'arm.policies.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)
        
        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_local_absolute_path_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(absolute_path_with_file_name))
        
        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_local_absolute_path_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=absolute_path_with_file_name)

        self._local_file_finder.can_parse_path.assert_called_with(
            absolute_path_with_file_name)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_local_absolute_path_no_filename_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')

        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(absolute_path))
        
        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_local_absolute_path_no_filename_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)

        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=absolute_path)
        
        self._local_file_finder.can_parse_path.assert_called_with(
            absolute_path)

        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_local_relative_path_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)

        relative_path_with_file_name = join(
            relative_path,
            'arm.policies.json')

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(relative_path_with_file_name))

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_local_relative_path_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)

        relative_path_with_file_name = join(
            relative_path,
            'arm.policies.json')

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)
        
        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=relative_path_with_file_name)

        self._local_file_finder.can_parse_path.assert_called_with(
            relative_path_with_file_name)

        self._local_file_finder.can_parse_path.assert_called_with(
            relative_path_with_file_name)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_local_relative_path_no_filename_with_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)

        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)

        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path='file({})'.format(relative_path))

        self._local_file_finder.append_folders.assert_called_with(
            absolute_path,
            'arm.policies.json')

        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_local_relative_path_no_filename_without_function(self):
        
        module_version = ModuleVersionRetrieval(
            self._local_relative_main_module_using_function, 
            self._local_file_finder, 
            self._remote_file_finder)
        
        latest_version = '5.0'
        main_module = module_version._main_module
        module_name = 'net'

        absolute_path = \
            join(
                main_module,
                module_name,
                latest_version)

        absolute_path_with_file_name = \
            join(
                absolute_path,
                'arm.policies.json')

        relative_path = join(
            self._local_relative_main_module,
            module_name,
            latest_version)

        self._local_file_finder.can_parse_path =\
            MagicMock(return_value=True)

        self._local_file_finder.is_directory =\
            MagicMock(return_value=True)
        
        self._local_file_finder.append_folders =\
            MagicMock(return_value=absolute_path_with_file_name)

        self._local_file_finder.read_file =\
            MagicMock(return_value=self._template_parameters)

        contents = module_version.get_policy_file(
            version='NOT CONSIDERED',
            module_name='NOT CONSIDERED',
            path=relative_path)
        
        self._local_file_finder.can_parse_path.assert_called_with(
            relative_path)

        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)

        self._local_file_finder.append_folders.assert_called_with(
            absolute_path,
            'arm.policies.json')

        self._local_file_finder.read_file.assert_called_with(
            fail_on_not_found=True,
            path=absolute_path_with_file_name)

        self.assertEqual(contents, self._template_parameters)

    def test_get_policy_file_using_invalid_local_path_without_function_expected_valueError(self):
        
        with self.assertRaises(ValueError) as excinfo:        
            module_version = ModuleVersionRetrieval(
                self._local_relative_main_module_using_function, 
                self._local_file_finder, 
                self._remote_file_finder)
        
            relative_path = join(
                'SOME',
                'FOLDER',
                'THAT',
                'DOES NOT',
                'EXISTS')

            module_version.get_policy_file(
                version='NOT CONSIDERED',
                module_name='NOT CONSIDERED',
                path=relative_path)

        self.assertEqual(excinfo.expected, ValueError)
        self.assertEqual(
            str(excinfo.exception), 
            'Invalid path. Allowed values are local path (file or dir must exist) or URL. Received: {}'.format(
                relative_path))

    def test_get_policy_file_using_invalid_local_path_with_function_expected_valueError(self):
        with self.assertRaises(ValueError) as excinfo:        
            module_version = ModuleVersionRetrieval(
                self._local_relative_main_module_using_function, 
                self._local_file_finder, 
                self._remote_file_finder)
        
            relative_path = join(
                'SOME',
                'FOLDER',
                'THAT',
                'DOES NOT',
                'EXISTS')

            self._local_file_finder.is_directory =\
                MagicMock(return_value=True)

            module_version.get_policy_file(
                version='NOT CONSIDERED',
                module_name='NOT CONSIDERED',
                path='file({})'.format(relative_path))
        
        absolute_path = os.path.abspath(relative_path)
        self._local_file_finder.is_directory.assert_called_with(
            absolute_path)
        self.assertEqual(excinfo.expected, ValueError)

        if self._is_windows_os:
            self.assertEqual(
            str(excinfo.exception), 
            'File not found, path searched: {}\\arm.policies.json'.format(
                absolute_path))
        else:
            self.assertEqual(
            str(excinfo.exception), 
            'File not found, path searched: {}/arm.policies.json'.format(
                absolute_path))

        
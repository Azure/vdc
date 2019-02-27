from orchestration.common.ifile_finder import FileFinderInterface
import re
import os
import urllib3
from orchestration.common import helper

class ModuleVersionRetrieval(object):
    
    def __init__(
        self, 
        main_module: str,
        local_file_finder: FileFinderInterface,
        remote_file_finder: FileFinderInterface,
        parameter_file_name: str = 'azureDeploy.parameters.json',
        deployment_file_name: str = 'azureDeploy.json',
        policy_file_name: str = 'arm.policies.json'):

        self._parameter_file_name = parameter_file_name
        self._deployment_file_name = deployment_file_name
        self._policy_file_name = policy_file_name
        self._is_local_main_module = False
        self._is_remote_main_module = False
        self._local_file_finder = local_file_finder
        self._remote_file_finder = remote_file_finder

        if 'file(' in main_module or \
             self._local_file_finder.can_parse_path(main_module):

            self._is_local_main_module = True
        elif 'url(' in main_module or \
            self._remote_file_finder.can_parse_path(main_module):

            self._is_remote_main_module = True
        else:
            raise ValueError('Invalid main module path. Allowed values are local path (dir must exist) or URL. Received: {}'.format(main_module))

        self._main_module = \
             helper.retrieve_path(main_module)
    
    def get_template_file(
        self, 
        version: str,
        module_name: str,
        path: str = None,
        fail_on_not_found: bool = True) -> dict:
        """Function that retrieves the template path based on the version passed and
        path. 
        If path is passed, it overrides the main_module from __init__
        :param version: Version value, if "latest" is passed, the function will search for the latest version
        :type version: str
        :param path: Template path, if passed, it overrides main_module from __init__
        :type path: str
        :raises: :class:`Exception`
        """
        
        file_content = self._file_contents(
            version=version,
            module_name=module_name,
            default_file_name=self._deployment_file_name,
            path=path,
            fail_on_not_found=fail_on_not_found)
        
        return file_content

    def get_parameters_file(
        self, 
        version: str,
        module_name: str,
        path: str = None,
        fail_on_not_found: bool = True):
        """Function that retrieves the parameters path based on the version passed and
        path. 
        If path is passed, it overrides the main_module from __init__
        :param version: Version value, if "latest" is passed, the function will search for the latest version
        :type version: str
        :param path: Template path, if passed, it overrides main_module from __init__
        :type path: str
        :raises: :class:`Exception`
        """
        file_content = self._file_contents(
            version=version,
            module_name=module_name,
            default_file_name=self._parameter_file_name,
            path=path,
            fail_on_not_found=fail_on_not_found)
        
        return file_content

    def get_policy_file(
        self,
        version: str,
        module_name: str,
        path: str = None,
        subscription_policy: bool = False,
        management_group_policy: bool = False,
        fail_on_not_found: bool = True):
        """Function that retrieves the Azure policy path based on the version passed and
        path. 
        If path is passed, it overrides the main_module from __init__
        :param version: Version value, if "latest" is passed, the function will search for the latest version
        :type version: str
        :param path: Template path, if passed, it overrides main_module from __init__
        :type path: str
        :raises: :class:`Exception`
        """

        if subscription_policy:
            if self._is_local_main_module:

                module_path = \
                    self._local_file_finder.append_folders(
                        self._main_module,
                        module_name)
                
                if self._local_file_finder.is_directory(module_path):
                    version = \
                            self.get_latest_local_module_version(module_name)
                    
                    path = \
                        self._local_file_finder.append_folders(
                            self._main_module,
                            'policies',
                            'subscription',
                            version,
                            self._policy_file_name)
                else:
                    # No policies/subscription module exists, exit
                    return
            else:
                # TODO: Get latest version from remote location
                version = "latest"
                path = \
                    self._remote_file_finder.append_folders(
                        self._main_module,
                        'policies',
                        'subscription',
                        version,
                        self._policy_file_name)
        
        file_content = self._file_contents(
            version=version,
            module_name=module_name,
            default_file_name=self._policy_file_name,
            path=path,
            fail_on_not_found=fail_on_not_found)

        return file_content

    def _file_contents(
        self, 
        version: str,
        module_name: str,
        default_file_name: str,
        fail_on_not_found: bool,
        path: str = None) -> dict:
        """Function that retrieves the template path based on the version passed and
        path. 
        If path is passed, it overrides the main_module from __init__
        :param version: Version value, if "latest" is passed, the function will search for the latest version
        :type version: str
        :param path: Template path, if passed, it overrides main_module from __init__
        :type path: str
        :raises: :class:`Exception`
        """

        if 'url(' in self._main_module and\
           version is not None and\
           version.lower().strip() == "latest":
           raise ValueError("Latest version not supported when retrieving a module from a remote location")

        if 'url(' in self._main_module and\
           path is None and\
           version is None:
           raise ValueError("Version must be provided when retrieving a remote module and path is not overridden")

        is_local_file = True
        file_content = ''

        if path is None and\
           self._is_local_main_module and\
           ( version is None or\
             version.lower().strip() == "latest"):
            
            version = self.get_latest_local_module_version(module_name)

            path = \
                self._local_file_finder.append_folders(
                    self._main_module,
                    module_name,
                    version,
                    default_file_name)
        elif path is None and\
           self._is_local_main_module and\
           version is not None and\
           len(version) > 0:

            path = \
                self._local_file_finder.append_folders(
                    self._main_module,
                    module_name,
                    version,
                    default_file_name)
        elif path is None and\
             self._is_remote_main_module:

            path = \
                self._remote_file_finder.append_folders(
                    self._main_module,
                    module_name,
                    version,
                    default_file_name)
            is_local_file = False
        else:
            tmp_path =\
                helper.retrieve_path(path)

            if 'file(' in path or \
                 self._local_file_finder.can_parse_path(path):
                
                # Assign tmp_path to path, tmp_path is required so that path
                # remains intact to evaluate if its value contains a file()
                # or url() function
                path = os.path.abspath(tmp_path)
                
                if  self._local_file_finder.is_directory(path):
                    
                    path = self._local_file_finder.append_folders(
                                path, 
                                default_file_name)

            elif 'url(' in path or \
                self._remote_file_finder.can_parse_path(path):
                
                # TODO: Pending update. Validate if the end of the URL is an extension
                is_local_file = False
                path = tmp_path
                path_split = path.split('/')

                if  len(path_split) > 0 and \
                    path_split[len(path_split) - 1] != default_file_name:
                    
                    path = self._remote_file_finder.append_folders(
                                path, 
                                default_file_name)
            elif not fail_on_not_found:
                exit
            else:
                raise ValueError('Invalid path. Allowed values are local path (file or dir must exist) or URL. Received: {}'.format(path))

        if is_local_file:
            file_content =\
                self._local_file_finder.read_file(
                    path=path,
                    fail_on_not_found=fail_on_not_found)
        else:
            file_content =\
                self._remote_file_finder.read_file(
                    path=path,
                    fail_on_not_found=fail_on_not_found)
        
        return file_content
    
    def _is_local_directory(
        self,
        path: str):

        return os.path.isdir(path)
    
    def get_latest_local_module_version(
        self,
        module_name: str) -> str:
        """Function that retrieves the latest version of a given module.
        Latest version is retrieved in two situations: 
            1. version = "latest"
            2. version value was not provided
        If no version is found in the repo, an exception is thrown.
        :param module_name: Module to search
        :type module_name: str 
        :return param version: returns the module latest version
        :return type version: str
        """
        all_folders = self._get_all_local_version_folders(module_name)
        if len(all_folders) > 0:
            all_folders = sorted(all_folders, reverse=True)
            return all_folders[0]
        else:
            None
    
    def _get_all_local_version_folders(
        self,
        module_name: str) -> list:
        """Function that resolves the main module reference -> file() or uri().
        If it is file() the function will attempt to read from a local folder.
        If it is uri() the function will attempt to execute an HTTP Get request.
         Make sure that the URI is not password protected.
         If it is a storage account set as private blob, make sure to add the
         Shared Access Signature (SAS) in the URL.
        If no version is found in the repo, an exception is thrown.
        :param module_name: Module to search
        :type module_name: str 
        :return param version: returns the module latest version
        :return type version: str
        """
        module_path = \
            self._local_file_finder.append_folders(
                self._main_module,
                module_name)
        
        return self._local_file_finder.get_all_folders(
                    module_path)
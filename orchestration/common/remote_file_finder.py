from pathlib import Path
from os.path import join
from interface import implements
from orchestration.common.ifile_finder import FileFinderInterface
import json
import re
import urllib3

class RemoteFileFinder(implements(FileFinderInterface)):
    
    def get_all_folders(
        self,
        root_path: str) -> list:
        raise NotImplementedError('Function not implemented')

    def get_all_folders_and_file_names(
        self,
        root_path: str) -> list:
        raise NotImplementedError('Function not implemented')

    def append_folders(
        self,
        main_path: str,
        *paths) -> str:
        
        folder = main_path

        for p in paths:
            folder =  '{}/{}'.format(folder, p)

        return folder

    def read_file(
        self,
        path: str,
        fail_on_not_found: bool = True) -> dict:
        
        
        http = urllib3.PoolManager()
        response = http.request('GET', path)
        data = response.data.decode('utf-8')

        if response.status != '200' and fail_on_not_found:
            raise ValueError('Remote file not found, URI: {}'.format(path))
        elif response.status != '200':
            return None
        else:
            return json.loads(data)

    def can_parse_path(
        self,
        path: str ) -> bool:

        parsed_url = self._find_url(path)

        if len(parsed_url) == 1:
            return True
        else:
            return False

    def _find_url(
        self,
        path: str) -> list:
        # findall() has been used  
        # with valid conditions for urls in string 
        url = re.findall(r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+] |[!*\(\), ]|(?:%[0-9a-fA-F][0-9a-fA-F]))+', path) 
        return url 
        
    def is_directory(
        self,
        path: str) -> bool:

        raise NotImplementedError()
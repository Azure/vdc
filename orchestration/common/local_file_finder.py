from pathlib import Path
from os.path import join
from interface import implements
from orchestration.common.ifile_finder import FileFinderInterface
import json
import re
import os

class LocalFileFinder(implements(FileFinderInterface)):

    def get_all_folders(
        self,
        root_path: str) -> list:

        p = Path(root_path)

        # List comprehension
        [f for f in p.iterdir() if f.is_dir()]

        # This will also include the current directory '.'
        all_module_dirs = list(p.glob('**'))
        module_types = list()

        for module_dir in all_module_dirs:
            
            # exclude current directory
            if str(module_dir) != root_path:  
                # Let's split the directory   
                path_list = \
                    re.findall(r'[^\\/]+|[\\/]', str(module_dir))
                # Let's get the last item of the array
                module_types.append(path_list[len(path_list) - 1])
        
        return module_types

    def get_all_folders_and_file_names(
        self,
        root_path: str) -> list:
        
        path_list = list(Path(root_path).glob('**/*.*'))
        return path_list

    def append_folders(
        self,
        main_path: str,
        *paths) -> str:

        folder = main_path

        for p in map(os.fspath, paths):
            folder = join(folder, p)

        return folder

    def read_file(
        self,
        path: str,
        fail_on_not_found: bool = True) -> dict:
        
        local_file: dict = None
        
        if not os.path.isabs(path):
            path = os.path.abspath(path)
            
        if  not Path(path).exists() and\
            fail_on_not_found:
            raise ValueError('File not found, path searched: {}'. format(
                    path))
        elif not Path(path).exists():
            return None
        else:
            with open(path, 'r') as template_file_fd:
                local_file = json.load(template_file_fd)

        return local_file

    def can_parse_path(
        self,
        path: str) -> bool:

        path = os.path.abspath(path)

        if os.path.isdir(path):
            return True
        elif os.path.isfile(path):
            return True
        else:
            return False
    
    def is_directory(
        self,
        path: str) -> bool:

        return os.path.isdir(path)
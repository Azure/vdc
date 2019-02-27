from interface import Interface
class FileFinderInterface(Interface):
    
    def get_all_folders(
        self,
        root_path: str) -> list:
        pass

    def get_all_folders_and_file_names(
        self,
        root_path: str) -> list:
        pass

    def append_folders(
        self,
        main_path: str,
        *paths) -> str:
        pass

    def read_file(
        self,
        path: str,
        fail_on_not_found: bool = True) -> dict:
        pass

    def can_parse_path(
        self,
        path: str) -> bool:
        pass

    def is_directory(
        self,
        path: str) -> bool:
        pass
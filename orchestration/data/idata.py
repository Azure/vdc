from interface import implements, Interface
from orchestration.models.content_type import ContentType

class DataInterface(Interface):

    def storage_exists(self):
        pass

    def create_storage(self):
        pass

    def store_contents(
        self,
        content_type: ContentType,
        container_name: str,
        content_name: str,
        content_data: str = None,
        content_path: str = None):
        pass

    def get_contents(
        self,
        content_type: ContentType,
        container_name: str,
        content_name: str):
        pass
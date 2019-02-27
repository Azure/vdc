class ResourceModule(object):
    def __init__(
        self,
        module = None):

        self._module = ''
        self._resource_group_name = ''
        self._same_resource_group = False
        self._create_resource_group = True
        self._source: ResourceSource = None
        self._dependencies = list()
        
        if module is not None and type(module) is dict:
            if 'module' in module:
                self._module = module['module']
            
            if 'resource-group-name' in module:
                self._resource_group_name = module['resource-group-name']
            
            if 'same-resource-group' in module:
                self._same_resource_group = module['same-resource-group']

            if 'create-resource-group' in module:
                self._create_resource_group = module['create-resource-group']

            if 'source' in module:
                self._source = ResourceSource(module['source'])

            if 'dependencies' in module:
                self._dependencies = module['dependencies']

    def create_default(
        self,
        module_name: str):

        return ResourceModule(
            dict({
                'module': module_name,
                'source': dict({'version': 'latest'})
            }))

class ResourceSource(object):
    def __init__(
        self,
        source: dict):

        self._version = None
        self._template_path = None
        self._parameters_path = None
        self._policy_path = None

        if source is not None:
            if 'version' in source:
                self._version = source['version']
            
            if 'template-path' in source:
                self._template_path = source['template-path']
        
            if 'parameters-path' in source:
                self._parameters_path = source['parameters-path']

            if 'policy-path' in source:
                self._policy_path = source['policy-path']
        
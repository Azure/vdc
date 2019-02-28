from azure.keyvault import KeyVaultClient
from azure.keyvault.models import SecretBundle
from orchestration.data.idata import DataInterface
from orchestration.models.content_type import ContentType
from os.path import join
from pathlib import Path
from queue import Queue
import time
import re
import json
import os

def get_current_time_milli():
    return int(round(time.time() * 1000))

def cleanse_output_parameters(output_data: str):
    return output_data.replace('"type": "String",', '')

def retrieve_path(module: str) -> str:

        # Retrieve function(s)
        function = re.findall(r'(.*)\(.*\)', module)
        
        if function is not None and len(function) > 1:
            raise ValueError('Invalid function received. Valid functions: file() or uri()')

        if function is not None and\
           len(function) == 1:

            function_operations = re.findall(r'\((.*?)\)', module)

            if function[0] == 'file':
                # Let's resolve absolute path
                module = os.path.abspath(function_operations[0])
            elif function[0] == 'url':
                module = function_operations[0]
            else:
                raise ValueError('Invalid function received. Valid functions: file() or uri()')
        
        return module

def sort_module_deployment(
    unsorted_list: list,
    source_order_list: list):

    tmp_sort_order: list = list()
    # tmp_unsorted_list will contain only the values to be sorted
    tmp_unsorted_list: list = list()
    # Let's get the index of each item in the original unsorted list
    # The index will help us sort the list later
    for item in unsorted_list:
        # Append only if the item is in the sorted list        
        if item in source_order_list:
            tmp_unsorted_list.append(item)
            tmp_sort_order.append(source_order_list.index(item))

    return [item for _, item in sorted(zip(tmp_sort_order, tmp_unsorted_list))]

def replace_all_tokens(
    dict_with_tokens: dict,
    parameters: dict,
    organization_name: str,
    shared_services_deployment_name: str,
    workload_deployment_name: str,
    storage_container_name: str,
    environment_keys: dict,
    storage_access: DataInterface,
    validation_mode: bool = False):
    """Function that replaces tokens from the main configuration file (main parameters file)

    :param dict_with_tokens: JSON object representing main configuration file
    :type dict_with_tokens: dict
    :param parameters: Object containing values used to replace tokens from dict_with_tokens
    :type parameters: dict
    :param organization_name: Organization name value
    :type organization_name: str
    :param shared_services_deployment_name: Shared Services deployment name value
    :type shared_services_deployment_name: str
    :param workload_deployment_name: Workload deployment name value
    :type workload_deployment_name: str
    :param storage_container_name: VDC storage container name
    :type storage_container_name: str
    :param environment_keys: Environment keys containing values passed from the command line
    :type environment_keys: dict
    :param storage_access: Object representing VDC Blob storage 
    :type storage_access: DataInterface
    :param validation_mode (optional): Value set to True when running deployment validation
    :type validation_mode: bool
    """
    for key, value in dict_with_tokens.items():
        
        # Analyze if tokens exist
        if has_token(value):
            tvalue = type(value)
            if tvalue is dict:
                for _key, _value in value.items():
                    # Example: 
                    # {
                    #   'par1': {
                    #       'par11': '${some.token}
                    #   }
                    # }
                    if type(_value) == str and has_token(_value):
                        _replace_all_tokens(
                            dict_with_tokens=dict_with_tokens,
                            parent_key=key,
                            value=dict({ _key : _value }),
                            parameters=parameters,
                            organization_name=organization_name,
                            shared_services_deployment_name=shared_services_deployment_name,
                            workload_deployment_name=workload_deployment_name,
                            storage_container_name=storage_container_name,
                            environment_keys=environment_keys,
                            storage_access=storage_access,
                            validation_mode=validation_mode)                                      
                    elif has_token(_value):
                        _replace_all_tokens(
                            dict_with_tokens=dict_with_tokens,
                            parent_key="{}.{}".format(key,_key),
                            value=_value,
                            parameters=parameters,
                            organization_name=organization_name,
                            shared_services_deployment_name=shared_services_deployment_name,
                            workload_deployment_name=workload_deployment_name,
                            storage_container_name=storage_container_name,
                            environment_keys=environment_keys,
                            storage_access=storage_access,
                            validation_mode=validation_mode)
            elif tvalue is list:
                index = 0
                for item in value:
                    if type(item) == str and has_token(item):
                        _replace_all_tokens(
                            dict_with_tokens=dict_with_tokens,
                            parent_key=None,
                            value=dict({ "{}.{}".format(key, str(index)) : item }),
                            parameters=parameters,
                            organization_name=organization_name,
                            shared_services_deployment_name=shared_services_deployment_name,
                            workload_deployment_name=workload_deployment_name,
                            storage_container_name=storage_container_name,
                            environment_keys=environment_keys,
                            storage_access=storage_access,
                            validation_mode=validation_mode)                                      
                    elif has_token(item):
                        _replace_all_tokens(
                            dict_with_tokens=dict_with_tokens,
                            parent_key="{}.{}".format(key, str(index)),
                            value=item,
                            parameters=parameters,
                            organization_name=organization_name,
                            shared_services_deployment_name=shared_services_deployment_name,
                            workload_deployment_name=workload_deployment_name,
                            storage_container_name=storage_container_name,
                            environment_keys=environment_keys,
                            storage_access=storage_access,
                            validation_mode=validation_mode)
                    index = index + 1
            elif tvalue == str:
                _replace_all_tokens(
                    dict_with_tokens=dict_with_tokens,
                    parent_key=None,
                    value=dict({ key : value }),
                    parameters=parameters,
                    organization_name=organization_name,
                    shared_services_deployment_name=shared_services_deployment_name,
                    workload_deployment_name=workload_deployment_name,
                    storage_container_name=storage_container_name,
                    environment_keys=environment_keys,
                    storage_access=storage_access,
                    validation_mode=validation_mode)
            else:
                raise ValueError('Type not supported. Received: {}'.format(tvalue))
   
    return dict_with_tokens

def _tryInt(value):
    try:
        int(value)
        return True
    except Exception:
        return False

def _replace_all_tokens(
    dict_with_tokens: dict,
    parent_key: str,
    value,
    parameters: dict,
    organization_name: str,
    shared_services_deployment_name: str,
    workload_deployment_name: str,
    storage_container_name: str,
    environment_keys: dict,
    storage_access: DataInterface,
    validation_mode: bool = False):
    
    # BFS
    # Replacement leaving a breadcrumb of each parent key
    q = Queue()

    if type(value) is dict:
        root = value.keys()
        for item in root:
            if parent_key is not None:
                q.put(dict({ "{}.{}".format(parent_key, item) : value[item] }))
            else:
                q.put(dict({ "{}".format(item) : value[item] }))

    elif type(value) is list:
        root = value
        index = 0
        for item in root:
            if parent_key is not None:
                q.put(dict({ "{}.{}".format(parent_key, str(index)) : item }))
            else:
                q.put(dict({ "{}".format(str(index)) : item }))
            index = index + 1
    else:
        # Raise exception, type not supported
        raise ValueError("Invalid type received. Type: {}, Expected: <dict> or <list>".format(type(value)))

    while not q.empty():

        item_in_queue = q.get()
        # Let's check if there is a token, otherwise ignore it
        for k,v in item_in_queue.items():
            if has_token(v):
                # Let's get the type
                type_v = type(v)
                if type_v is dict:
                    for _k,_v in v.items():
                        # Format the dict key like this: parentKey.childKey, 
                        # this will be used later to split the keys and update the right value
                        q.put(dict( { 
                            "{}.{}".format(k, _k) : _v 
                        } ))
                elif type_v is list:
                    index = 0
                    for _v in v:
                        # Format the dict key like this: parentIndex.childIndex, 
                        # this will be used later to split the keys and update the right value
                        q.put(dict( { 
                            "{}.{}".format(k, str(index)) : _v 
                        } ))
                        index = index + 1
                elif type_v is str:
                    
                    # Split key, to find the proper key to replace. Key might be in the form
                    # of parentKey.childKey
                    parent_keys = k.split('.')
                    
                    if len(parent_keys) > 1:

                        key_is_integer = _tryInt(parent_keys[0])

                        # Position on the first parent
                        if key_is_integer:
                            # Parse key
                            parent = dict_with_tokens[int(parent_keys[0])]
                        else:
                            parent = dict_with_tokens[parent_keys[0]]
                        
                        # Loop through the rest of the parent keys
                        # to get to the dict reference which value
                        # will be replaced
                        _key = None

                        # Loop until the previous from the last parent key.
                        # If we loop until the last parent key, then 
                        # "parent" variable will become the value of the 
                        # last parent instead of being the reference to replace.
                        # Example, say we have parent1.parent2 as parent_keys and values
                        # 1 and 2 respectively, and we want to replace parent2 value to 
                        # be, let's say number 3.
                        # Looping through all the parents, will assign "parent" variable
                        # to the value of parent1 and parent2, but what we actually need
                        # is parent = parent2, to be able to do parent[parent2] = 3
                        for parent_key in range(1, len(parent_keys) - 1):
                            # If is an integer, it means is an index
                            # of an array
                            if _tryInt(parent_keys[parent_key]):
                                _key = int(parent_keys[parent_key])
                            else:
                                _key = parent_keys[parent_key]

                            parent = parent[_key]
                    
                        # Let's get the last parent key
                        if _tryInt(parent_keys[len(parent_keys) - 1]):
                            last_parent_key = int(parent_keys[len(parent_keys) - 1])
                        else:
                            last_parent_key = parent_keys[len(parent_keys) - 1]
                    else:
                        parent = dict_with_tokens
                        last_parent_key = parent_keys[0]
                    
                    # Replace parent's value (last index | first index, 
                    # of the split)

                    parent[last_parent_key] = \
                        _replace_token(
                            parameters = parameters,
                            value_with_token = parent[last_parent_key],
                            shared_services_deployment_name = shared_services_deployment_name,
                            workload_deployment_name = workload_deployment_name,
                            organization_name = organization_name,
                            storage_container_name = storage_container_name,
                            storage_access = storage_access,
                            validation_mode = validation_mode,
                            environment_keys=environment_keys)

def _replace_token(
    parameters: dict,
    value_with_token: str,
    shared_services_deployment_name: str,
    workload_deployment_name: str,
    organization_name: str,
    storage_container_name: str,
    storage_access: DataInterface,
    environment_keys: dict,
    validation_mode: bool = False):


    if environment_keys is not None:
        parameters.update(environment_keys)

    if 'env:' in value_with_token.lower():
        # If the original token contains ENV:XXXXXX references (environment keys)
        # let's replace the environment keys with its respective values
        # i.e. value_with_token = "contoso-${ENV:ENVIRONMENT-TYPE.test.me}"
        # will get replaced (assuming ENV:ENVIRONMENT-TYPE = shared-services)
        # contoso-shared-services.test.me
        value_with_token = \
            _replace_original_token(
                value_with_token,
                environment_keys)


    tokens_found = re.findall('\\$\\{(.*?)}', value_with_token)
    value_found = None

    if len(tokens_found) == 1:
        value_found = _get_value_from_parameters(
            parameters,
            tokens_found[0],
            shared_services_deployment_name,
            workload_deployment_name,
            organization_name,
            storage_container_name,
            storage_access,
            validation_mode)

        # One token found, let's find if there is additional text to the left or right, if there is
        # it means the value to replace must be a concat of strings.
        # Example, value_with_token = "${general.organization-name}-net-rg"
        
        # Lookbehind RE
        right = re.search('(?<=\\$\\{' + tokens_found[0] + '}).*$', value_with_token)
        # Lookahead RE
        left = re.search('^.*?(?=\\$\\{' + tokens_found[0] + '})', value_with_token)

        if ( right is not None and right.group(0) != '' ) or \
           ( left is not None and left.group(0) != '' ):
            value_found = \
                value_with_token.replace("${" + tokens_found[0] + "}", str(value_found))
            
    elif len(tokens_found) > 1:
        for token in tokens_found:

            value = _get_value_from_parameters(
                parameters,
                token,
                shared_services_deployment_name,
                workload_deployment_name,
                organization_name,
                storage_container_name,
                storage_access,
                validation_mode)
            
            # Currently we only support concatenating strings values
            # Example of token: '${workload.deployment-name}-${workload.extension-name}'
            # In this case, deployment-name and extension-name must be strings
            value_with_token = \
                value_with_token.replace("${" + token + "}", str(value))
            
        value_found = value_with_token

    return value_found

def _replace_tokens_found(
    token: str,
    environment_keys: dict):
    
    env_keys = [tt for tt in token.split('.') if 'env:' in tt.lower()]
    for ek in env_keys:
        token = token.replace(ek, environment_keys[ek.upper()])
    return token

def _replace_original_token(
    token: str,
    environment_keys: dict):
    
    # If split('.') is equals to 1, it means that the token
    # is something like: ${ENV:XXXXX}, 
    # i.e. contoso/${ENV:ENVIRONMENT-KEY} this value will be 
    # replaced by the function _replace_token first if condition.
    # This function only replaces environment keys when the token
    # is something like: contoso/${ENV.ENVIRONMENT-KEY.prop1.prop2}
    # ${ENV.ENVIRONMENT-KEY.prop1.prop2} will resolve in something
    # like: ${shared-services.prop1.prop2}, and this token will be 
    # resolved by the function _replace_token first if condition.
    
    tokens_found = re.findall(r'\$\{(.*?)}', token)
    
    for token_found in tokens_found:
        if 'env:' in token_found.lower() and\
            len(token_found.split('.')) == 1:
                continue
        elif 'env:' in token_found.lower():
            env_keys = [tt for tt in token_found.split('.') if 'env:' in tt.lower()]
            for ek in env_keys:
                token = \
                    token\
                        .replace(
                            ek, 
                            environment_keys[ek.upper()])
    return token

def _get_value_from_parameters(
    parameters: dict,
    tokens_found: str,
    shared_services_deployment_name: str,
    workload_deployment_name: str,
    organization_name: str,
    storage_container_name: str,
    storage_access: DataInterface,
    validation_mode: bool = False):

    value_found = None
    
    # Let's split the token to fetch the proper key
    positional_parameters = tokens_found.split('.') # i.e. 'workload.param1.param2' string
    
    if len(positional_parameters) > 1 and \
        positional_parameters[0].lower().strip() == 'external' and \
        not validation_mode:
        
        # Let's get the deployment name based on the deployment type
        deployment_name = shared_services_deployment_name
        
        # If deployment type is workload, let's set workload deployment name
        if positional_parameters[1].lower().strip() == 'workload':
            deployment_name = workload_deployment_name

        # Let's get output paramaters from storage location.
        # Format should be -> external.shared_services|workload.module.parameter
        storage_content_name = "{}-{}-{}/parameters/{}/azureDeploy.parameters.output.json".format(
            organization_name,
            positional_parameters[1],
            deployment_name,
            positional_parameters[2])
        
        output_parameter = storage_access.get_contents(
            ContentType.TEXT, 
            storage_container_name, 
            storage_content_name)
        
        value_found = output_parameter[positional_parameters[3]]
    elif len(positional_parameters) > 1 and \
        positional_parameters[0].lower().strip() == 'external' and \
        validation_mode:
        value_found = "dummy"
    elif len(positional_parameters) > 1:
        index = 0
        value_found = None
        
        for positional_parameter in positional_parameters:
            
            # Let's get the value of the first index -> parameters['workload'] (from above, 'parameters' is a dictionary)
            # so we can keep analyzing the rest of the properties until we get the desired value
            # From above: value_found = parameters['workload'], 'workload' because positional_parameters[0] is = 'workload'
            # next iteration results in analyzing workload.param1 because we are doing value_found['param1']
            if index == 0:
                value_found = parameters[positional_parameters[0]]
                
                index = index + 1
                continue
            
            if '[' in positional_parameter:
                # We are trying to retrieve an array index

                # Let's get the parameter key
                tmp_positional_parameter = positional_parameter[0: positional_parameter.index('[')]
                # Let's get the index
                tmp_index = positional_parameter[positional_parameter.index('[') + 1: \
                                                 positional_parameter.index(']')]
                
                # Let's get the array values
                tmp_value_found = value_found[tmp_positional_parameter]

                if type(tmp_value_found) is not list:
                    raise ValueError("Invalid property. \
                        Expected a list and received: {}".format(
                            type(tmp_value_found)))
                # Let's get the index we are searching for and keep looping
                value_found = tmp_value_found[int(tmp_index)]
                continue

            value_found = value_found[positional_parameter]
            
            index = index + 1
    else:
        value_found = parameters[tokens_found]
    
    return value_found

def has_token(
    object_to_analyze):

    regex_pattern = '\\$\\{(.*?)}'
    return re.search(regex_pattern, json.dumps(object_to_analyze)) != None

def replace_string_tokens(
    full_text_with_tokens: str,
    parameters: dict,
    organization_name: str,
    shared_services_deployment_name: str,
    workload_deployment_name: str,
    storage_container_name: str,
    storage_access: DataInterface,
    validation_mode: bool = False):
    
    all_tokens = re.findall('\\$\\{(.*?)}', full_text_with_tokens)

    for token in all_tokens:
        token_split = token.split('.')
        value: str = ''
        # validation_mode argument specifies whether or not we are doing a deployment validation.
        # if we are doing a deployment validation, then do not go to the storage account to fetch information
        if len(token_split) > 1 and token_split[0].lower().strip() == 'external' and not validation_mode:
            
            # Let's get the deployment name based on the deployment type
            deployment_name = shared_services_deployment_name
            
            # If deployment type is workload, let's set workload deployment name
            if token_split[1].lower().strip() == 'workload':
                deployment_name = workload_deployment_name
            
            # Let's get output paramaters from storage location.
            # Format should be -> external.shared_services|workload.module.parameter
           
            storage_content_name = "{}-{}-{}/parameters/{}/azureDeploy.parameters.output.json".format(
                    organization_name,
                    token_split[1],
                    deployment_name,
                    token_split[2])
            
            output_parameters = storage_access.get_contents(
                ContentType.TEXT, 
                storage_container_name, 
                storage_content_name)

            # Deserialize the string
            json_output = json.loads(output_parameters)

            value = json_output[token_split[3]]['value']
        elif len(token_split) > 1 and token_split[0].lower().strip() == 'external' and validation_mode:
            value = "dummy"
        elif len(token_split) > 1:
            value = parameters[token_split[0]][token_split[1]]
        else:
            value = parameters[token_split[0]]
        
        full_text_with_tokens = full_text_with_tokens.replace(
            '${' + token + '}', 
            value)

    return full_text_with_tokens

def operations(
    full_text: str,
    parameters: dict):

    operations = ["next-ip"]

    for operation in operations:
        if operation == 'next-ip':
            full_text = _next_ip(full_text, parameters)

    return full_text

def _next_ip(
    full_text: str,
    parameters: dict):

    all_operations = re.findall(r'next-ip\((.*?)\)', full_text)
    
    #Let's proceed to execute the calculation
    for operation in all_operations:
        # Proceed to replace the tokens, if any
        replaced_string = replace_string_tokens(
            operation, 
            parameters,
            None,
            None,
            None,
            None,
            None)

        operands = replaced_string.split(',') #Format -> next-ip(ip, offset)
        ip = operands[0]
        offset = operands[1]
        ip_values = ip.split('.')
        value_to_increment = ip_values[len(ip_values) - 1]
        new_value = int(value_to_increment) + int(offset.strip())
        # Let's construct the new IP
        new_ip = '{}.{}.{}.{}'.format(
            ip_values[0],
            ip_values[1],
            ip_values[2],
            new_value)
        # Let's replace the value in the original string
        full_text = full_text.replace('next-ip({})'.format(operation), new_ip)
    return full_text

def truncate_string_arguments(
    max_size_of_string: int,
    value_to_truncate: str):
    
    return value_to_truncate[:max_size_of_string]

def create_unique_string(
        original_value: str,
        max_length: int):

        current_milli = get_current_time_milli()
        
        original_value = '{}{}'.format(
            original_value,
            str(current_milli))
                
        original_value = original_value[:max_length]

        return original_value

def findAll_regex(
    regex_pattern: str,
    text: str) -> list:
    return re.findall(regex_pattern, text)

def save_json_file(
    output: dict, 
    path: str):
    
    with open(path, 'w+') as f:
        f.write(json.dumps(output))

def modify_json_file(
    prop_value: object,
    prop_key: str,
    path: str):

    with open(path, 'r') as template_file_fd:
        local_file: dict = json.load(template_file_fd)
    
    # i.e. shared-services.network.subnets
    parent_keys = prop_key.split('.')

    # Position on first index
    parent = local_file[parent_keys[0]]
    for parent_key in range(1, len(parent_keys) - 1):
        _key = parent_keys[parent_key]
        parent = parent[_key]

    last_parent_key = parent_keys[len(parent_keys) - 1]
    parent[last_parent_key] = prop_value
    
    with open(path, "w+") as jsonFile:
        json.dump(local_file, jsonFile, indent=4)

def modify_json_object(
    prop_value: object,
    prop_key: str,
    json_object: dict):
    
    # i.e. shared-services.network.subnets
    parent_keys = prop_key.split('.')
    
    # Position on first index
    parent = json_object[parent_keys[0]]
   
    for parent_key in range(1, len(parent_keys) - 1):
        _key = parent_keys[parent_key]
        parent = parent[_key]
       
    last_parent_key = parent_keys[len(parent_keys) - 1]
    parent[last_parent_key] = prop_value

    return json_object
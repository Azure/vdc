from orchestration.models.script_type import ScriptType
from orchestration.common import helper

class CustomScriptExecution(object):
    
    def execute(
        self,
        script_type: ScriptType,
        command: str,
        output_file_path: str = None,
        property_path: str = None,
        file_path_to_update: str = None) -> dict:

        if script_type == ScriptType.POWERSHELL:
            from orchestration.integration.custom_scripts.powershell_execution import PowershellScriptExecution
            pwsh = PowershellScriptExecution()
            result = pwsh.execute(command)
        elif script_type == ScriptType.BASH:
            from orchestration.integration.custom_scripts.bash_execution import BashScriptExecution
            bash = BashScriptExecution()
            result = bash.execute(command)
        else:
            return ValueError('Invalid type received')

        if output_file_path is not None and\
           len(output_file_path) > 0:
            
            self.save_json_file(
                result,
                output_file_path)

        if property_path is not None and\
            len(property_path) > 0 and\
            file_path_to_update is not None and\
            len(file_path_to_update) > 0:
            
            self.modify_json_file(
                result= result,
                property_path= property_path,
                file_path_to_update= file_path_to_update)

        return result['output']
    
    def save_json_file(
        self, 
        result: dict, 
        output_file_path: str):
        
        helper.save_json_file(
            result['output'],
            output_file_path)

    def modify_json_file(
        self,
        result: dict, 
        property_path: str,
        file_path_to_update: str):
        
        helper.modify_json_file(
            prop_value= result['output'],
            prop_key= property_path,
            path= file_path_to_update)


            
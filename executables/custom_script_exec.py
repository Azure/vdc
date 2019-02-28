from pathlib import Path
from sys import argv
from argparse import ArgumentParser, FileType
from orchestration.integration.custom_scripts.script_execution import CustomScriptExecution
from logging.config import dictConfig
from orchestration.common import helper
from orchestration.models.script_type import ScriptType
import logging
import json

# Logging preperation.
#-----------------------------------------------------------------------------

# Set the log configuration using a json config file.        
if Path('logging/config.json').exists():
    with open('logging/config.json', 'rt') as f:
        config = json.load(f)
        dictConfig(config)
else:
    logging.basicConfig(level=logging.INFO)

# Create a new logger instance using the provided configuration.
_logger = logging.getLogger(__name__)

def _write_to_console(result: dict):
    import sys
    sys.stdout.write("\n")
    sys.stdout.write(json.dumps(result))
    sys.stdout.write("\n")
    sys.stdout.write("\n")

def _execute_custom_script(
    args,
    script_type: ScriptType):
    from orchestration.integration.custom_scripts.script_execution import CustomScriptExecution
    script_execution = CustomScriptExecution()
    return script_execution.execute(
        script_type=script_type,
        command=args.command,
        output_file_path=args.output,
        property_path=args.property_path,
        file_path_to_update=args.path)

def run_powershell_script(args):

    result = _execute_custom_script(
        args=args,
        script_type=ScriptType.POWERSHELL)

    if args.show:
        _write_to_console(result)

def run_bash_script(args):
    result = _execute_custom_script(
        args=args,
        script_type=ScriptType.BASH)
    
    if args.show:
        _write_to_console(result)
    
def set_default_arguments(parser):
        
    parser.add_argument('-c', '--command',
                dest='command',
                required=True,
                help='Custom script command. Powershell or Bash')

    parser.add_argument('-s', '--show',
                dest='show',
                required=False,
                action="store_true",
                help='Show output on console')

    parser.add_argument('-o', '--output',
                dest='output',
                required=False,
                help='Output file name')

    parser.add_argument('-property', '--property-path',
                dest='property_path',
                required=False,
                help='Property path, corresponds to a property from config.json')

    parser.add_argument('-path',
                dest='path',
                required=False,
                help='Config.json path to modify')

def main():
    
    #-----------------------------------------------------------------------------
    # Script argument definitions.
    #-----------------------------------------------------------------------------

    # Define a top level parser.
    parser = ArgumentParser(
        description='Set of commands to run custom scripts (Powershell or Bash)')
    
    # Create a subparser to distinguish between the different deployment commands.
    subparsers = parser.add_subparsers(
        help='Executes custom scripts. Output is a JSON string: { "output": "" }')

    powershell_subparser = subparsers\
        .add_parser(
            'powershell', 
            help='Executes custom powershell scripts')

    set_default_arguments(powershell_subparser)

    powershell_subparser\
        .set_defaults(
            func=run_powershell_script)
    
    bash_subparser = subparsers\
        .add_parser(
            'bash', 
            help='Executes custom bash scripts')

    set_default_arguments(bash_subparser)

    bash_subparser\
        .set_defaults(
            func=run_bash_script)
    
    #-----------------------------------------------------------------------------
    # Process parameter arguments.
    #-----------------------------------------------------------------------------

    # Gather the provided argument within an array.
    args = parser.parse_args()

    # Let's check if there are parameters passed, if not, print function usage
    if len(vars(args)) == 0:
        parser.print_usage()
        exit()
    
    #-----------------------------------------------------------------------------
    # Call the function indicated by the invocation command.
    #-----------------------------------------------------------------------------
    try:
        args.func(args)
    except Exception as ex:
        _logger.error('There was an error provisioning the resources: {}'.format(str(ex)))
        _logger.error(ex)
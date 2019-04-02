# Running from your local machine

This option for running the toolkit is typically used when customizing the scripts or extending the functionality of the toolkit.

The basic steps are:

1. Download the source files for the toolkit
1. [Install the Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest)
1. [Install Python](https://www.python.org/downloads/release/python-360/)
1. Configure your local environment

We recommend that you create a [virtual Python environment](https://docs.python.org/3/tutorial/venv.html) on your local machine to avoid versioning conflicts.

How you execute the scripts in the toolkit will vary by operating system:

*[Linux/OSX]*

`python3 some-script.py`

*[Windows]*

`py some-script.py`

## Software requirements

| Prerequisite | Minimum version
| :-           | :-
| Azure CLI    | 2.0.34
| Python       | 3.6 (3.7 not yet supported)

See [../requirements.txt] for Python package dependencies.

*[Linux/OSX]*

`python3 -m pip install -r requirements.txt`

*[Windows]*

`py -m pip install -r requirements.txt`

## Next steps

> Throughout the remainder of this documentation, be sure to use the commands labelled for your operating system: `[Linux/OSX]` or `[Windows]`.

You are now ready to start [your first deployment](../use/your-first-deployment.md).
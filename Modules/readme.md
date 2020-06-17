# Modules 2.0

A module is a reusable set of artifacts that can be composed into an archetype (environment).
The modules can be deployed by anything that can deploy ARM templates. There is no need for a proprietary tool for deploying a single module.
This document is about the 2.0 format for modules.

 At a minimum, a module _must_ have:

- deployment and parameters files (e.g `deploy.json` and `parameters.json`)
- a `readme.md` file
- tests (e.g. `module.tests.ps1`) - located in the *Tests* subfolder

In addition, a module may include the following (each in a subfolder named after the asset type):

- *Policy* (ARM template) definition + assignment
- *RBAC* (ARM template) definition + assignment
- *Scripts* (bash scripts, powershell, batch files, etc.)

## Guidelines

A module usually represents a single resource or a set of closely related resources.
For example, a storage account and the associated lock or virtual machine and network interfaces.

- Don't use hyphens in file names, folder names, parameters, or variables.
- Module names should use PascalCase and are derived from the names in the Azure Portal
- Parameters and variables in ARM template should use camelCase
- Don't use nested deployments pointing to different subscription and or resource group
    -  There are situations where nested deployments are okay (i.e., BitLocker – to encrypt the OS drive you’ll need to run a nested deployment)


## Testing

Tests rely on Powershell and [Pester](https://github.com/pester/Pester) and on ARM validation.

There are two test files:

- `module.tests.ps1` is required.
- `output.tests.ps1` is optional. The optional file is for debugging purposes. It writes deployment input parameters to the console.

 The module test verifies that required parameters are defined in the parameters file and verifies that the template file has the following parameters: 

``` Powershel
    $expectedProperties = '$schema',
    'contentVersion',
    'parameters',
    'variables',
    'resources',
    'outputs' | Sort-Object
```

Once all Pester test passes, proceed to run any of the following commands:

- Powershell:

`Test-AzResourceGroupDeployment`

- Azure CLI:

`az group deployment validate`

Before creating a PR, **make sure that these two type of tests pass.**
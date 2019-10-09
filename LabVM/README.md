# Azure Virtual Datacenter lab workstation

This one click deployment will build the toolkit development box in Azure.
All of the dependencies required to use the toolkit are installed.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvdc%2Fmaster%2FLabVM%2Fazure-deploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

> NOTE This can take 30 minutes to set up. Please be aware that if you login too early, the software won't be ready.

## Software included on the VM

1. Docker for Windows Community Edition
1. Git for Windows (bash)
1. Visual Studio Code with Extentions: Azure ARM Tools, Azure CLI, Python Linting, Docker, PowerShell

See the [`auzre-deploy.json` file for credentials](azure-deploy.json#L16-L17).

> NOTE Storing credentials in source code is a very bad practice.
> You should change these credentials as soon as you log into the VM.

## Starting Docker
- Once the VM is deployed use the Azure portal to connect.
- Double click the Docker for Windows shortcut on the desktop.
- It will take a few minutes for Docker to start the first time.
- You may need to sign out and sign back in for Docker to work.


## Next steps
Checkout the [quick start guide](../Docs/quickstart.md).
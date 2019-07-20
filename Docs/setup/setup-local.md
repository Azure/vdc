# Running from your local machine

The following component are the minimum to edit and execute the VDC toolkit:

1. [Install the Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest)
1. [Install Powershell Core 6.2.1](https://github.com/powershell/powershell)
1. Import Azure module: Az, ResourceGraph

## Automate Installation using Chocolatey on Windows

Chocolatey is a package manager for Windows to facilitate installation and update of softwware

Open Powershell as administrator

`Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`

Close and Open Powershell as Administrator

`choco install vscode powershell-core azure-cli pester`

## Install Azure Module in PowerShell 6

Open Powershell6 as Administrator

`Install-Module Az; Az.ResourceGraph -Force`

## Change Powershell Execution Policy

Open Powershell6 as Admintrator

`Set-Executionpolicy bypass`

## Known issue

You may receive a script halted error or tokens issue when you execute the VDC toolkit, reboot your machine to fix it.

# Next Steps

You are now ready to start [your first deployment](../use/your-first-deployment.md).

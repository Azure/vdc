#Enable Containers
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart

#Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#Assign Chocolatey Packages to Install
$Packages = 'googlechrome',`
            'docker-desktop',`
            'visualstudiocode',`
            'git'

#Install Chocolatey Packages
ForEach ($PackageName in $Packages)
{choco install $PackageName -y}

#Install Visual Studio Code Extensions
$Extensions = 'ms-vscode.azurecli',`
              'msazurermtools.azurerm-vscode-tools',`
              'ms-vscode.azure-account',`
              'ms-python.python',`
              'ms-vscode.powershell',`
              'peterjausovec.vscode-docker'

#Install Packages
Set-ExecutionPolicy Bypass -Scope Process -Force
ForEach ($ExtensionName in $Extensions)
{cmd.exe /C "C:\Program Files\Microsoft VS Code\bin\code.cmd" --install-extension $ExtensionName}

#Add LABVM UserId to docker group
Add-LocalGroupMember -Member vdcadmin -Group docker-users

#Reboot
Restart-Computer

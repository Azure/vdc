<#
	.NOTES
		==============================================================================================
		Copyright(c) Microsoft Corporation. All rights reserved.

		File:		key.vault.backup.ps1

		Purpose:	Key Vault Backup Automation Script

		Version: 	1.0.0.0 - 1st April 2019 - Azure Virtual Datacenter Development Team
		==============================================================================================

	.SYNOPSIS
		Key Vault Backup Automation Script

	.DESCRIPTION
		Key Vault Backup Automation Script

		Deployment steps of the script are outlined below.
		1) Set Azure KeyVault Parameters
		2) Setup Backup Directory
		3) Backup Key Vault Secrets
		4) Copy Files to Azure Files
		5) Create Backup Folder
		6) Upload Files
			
	.PARAMETER KeyVaultName
		Specify the Azure Key Vault Name parameter.

	.PARAMETER KeyVaultResourceGroup
		Specify the Key Vault Resource Group Name parameter.

	.PARAMETER StorageAccountName
		Specify the Storage Account Name parameter.
	
	.PARAMETER StorageResourceGroup
		Specify the Storage Resource Group Name parameter.
	
	.PARAMETER fileshareName
		Specify the File Share Name parameter.

	.PARAMETER backupFolder
		Specify the Backup Folder parameter.

	.PARAMETER tempRestoreFolder
		Specify the Temp Restore Folder parameter.

	.EXAMPLE
		Default:
		C:\PS>.\key.vault.backup.ps1 `
			-KeyVaultName <"KeyVaultName"> `
			-KeyVaultResourceGroup <"KeyVaultResourceGroup> `
			-StorageAccountName <"StorageAccountName"> `
			-StorageResourceGroup <"StorageResourceGroup"> `
			-fileshareName <"fileshareName"> ` 
			-backupFolder <"backupFolder">
#>

#Requires -Version 5
#Requires -Module AzureRM.KeyVault
#Requires -Module AzureRM.Storage
#Requires -Module Azure.Storage

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string]$keyVaultName,
	[Parameter(Mandatory = $true)]
	[string]$keyVaultResourceGroup,
	[Parameter(Mandatory = $true)]
	[string]$StorageAccountName,
	[Parameter(Mandatory = $true)]
	[string]$StorageResourceGroup,
	[Parameter(Mandatory = $true)]
	[string]$fileshareName,
	[string]$backupFolder = "$env:Temp\KeyVaultBackup"
)

#region - Setup Backup Directory
if (test-path $backupFolder)
{
	$paramRemoveItem = @{
		Path    = $backupFolder
		Recurse = $true
		Force   = $true
	}
	Remove-Item @paramRemoveItem
}
#endregion

#region - Backup Key Vault Secrets
$paramNewItem = @{
	ItemType = 'Directory'
	Force    = $true
	Path	 = $backupFolder
}
New-Item @paramNewItem | Out-Null

Write-Output "Starting backup of KeyVault to local directory"

#region - Certificates
$paramGetAzureKeyVaultCertificate = @{
	VaultName = $keyvaultName
}
$certificates = Get-AzureKeyVaultCertificate @paramGetAzureKeyVaultCertificate

foreach ($cert in $certificates)
{
	$paramBackupAzureKeyVaultCertificate = @{
		Name = $cert.name
		VaultName = $keyvaultName
		OutputFile = "$backupFolder\certificate-$($cert.name)"
	}
	Backup-AzureKeyVaultCertificate @paramBackupAzureKeyVaultCertificate | Out-Null
}
#endregion

#region - Secrets
$paramGetAzureKeyVaultSecret = @{
	VaultName = $keyvaultName
}
$secrets = Get-AzureKeyVaultSecret @paramGetAzureKeyVaultSecret

foreach ($secret in $secrets)
{
	#Exclude any secerets automatically generated when creating a cert, as these cannot be backed up   
	if (-not ($certificates.Name -contains $secret.name))
	{
		$paramBackupAzureKeyVaultSecret = @{
			Name = $secret.name
			VaultName = $keyvaultName
			OutputFile = "$backupFolder\secret-$($secret.name)"
		}
		Backup-AzureKeyVaultSecret @paramBackupAzureKeyVaultSecret | Out-Null
	}
}
#endregion

#region - Keys
$paramGetAzureKeyVaultKey = @{
	VaultName = $keyvaultName
}
$keys = Get-AzureKeyVaultKey @paramGetAzureKeyVaultKey

foreach ($kvkey in $keys)
{
	#Exclude any keys automatically generated when creating a cert, as these cannot be backed up   
	if (-not ($certificates.Name -contains $kvkey.name))
	{
		$paramBackupAzureKeyVaultKey = @{
			Name = $kvkey.name
			VaultName = $keyvaultName
			OutputFile = "$backupFolder\key-$($kvkey.name)"
		}
		Backup-AzureKeyVaultKey @paramBackupAzureKeyVaultKey | Out-Null
	}
}
#endregion

Write-Output "Local file backup complete"
#endregion

#region - Copy Files to Azure Files
Write-Output "Starting upload of backup to Azure Files"
$paramGetAzureRmStorageAccount = @{
	ResourceGroupName = $storageResourceGroup
	Name			  = $storageAccountName
}
$storageAccount = Get-AzureRmStorageAccount @paramGetAzureRmStorageAccount
$files = Get-ChildItem $backupFolder
$backupFolderName = Split-Path $backupFolder -Leaf
#endregion

#region - Create Backup Folder
$paramGetAzureStorageFile = @{
	Context = $storageAccount.Context
	ShareName = $fileshareName
	Path    = $backupFolderName
}
$backupFolderTest = Get-AzureStorageFile @paramGetAzureStorageFile

if (-not $backupFolderTest)
{
	$paramNewAzureStorageDirectory = @{
		Context = $storageAccount.Context
		ShareName = $fileshareName
		Path    = $backupFolderName
	}
	New-AzureStorageDirectory @paramNewAzureStorageDirectory
}
#endregion

#region - Upload Files
foreach ($file in $files)
{
	$paramSetAzureStorageFileContent = @{
		Context = $storageAccount.Context
		ShareName = $fileshareName
		Source  = $file.FullName
		Path    = "$backupFolderName\$($file.name)"
		Force   = $true
	}
	Set-AzureStorageFileContent @paramSetAzureStorageFileContent
}

$paramRemoveItem = @{
	Path    = $backupFolder
	Recurse = $true
	Force   = $true
}
Remove-Item @paramRemoveItem

Write-Output "Upload complete"

Write-Output "Backup Complete"
#endregion
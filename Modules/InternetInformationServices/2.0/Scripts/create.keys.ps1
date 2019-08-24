[CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $VaultName,
        [Parameter(Mandatory=$true)]
        [string]
        $KeyName,
        [Parameter(Mandatory=$false)]
        [string]
        $Destination,
        [Parameter(Mandatory=$false)]
        [bool]
        $ReplaceExistingKey = $false
    )
if ($null -eq $Destination) {
    $Destination = "HSM";
}

try {

    $result = `
        (Get-AzKeyVaultKey `
            -VaultName $VaultName `
            -Name $KeyName `
            -ErrorAction SilentlyContinue).Id;

    if (($null -eq $result) -or `
        $ReplaceExistingKey) {
        $result = (Add-AzKeyVaultKey `
            -VaultName $VaultName `
            -Name $KeyName `
            -Destination $Destination).Id;
    }

    return $result
}
catch {
    throw $_;
}


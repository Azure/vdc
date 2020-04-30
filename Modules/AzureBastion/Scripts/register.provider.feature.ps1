## Azure Government does not have this feature so it will always send the script into an infinite loop
#$installed = Get-AzProviderFeature -ProviderNamespace Microsoft.Network | Where-Object -Property "FeatureName" -EQ "AllowBastionHost" 

# I am adding the Microsoft.Network provider here instead of the bastion.
$installed = Get-AzResourceProvider -ProviderNamespace Microsoft.Network

if ($null -eq $installed) {
   # Register-AzProviderFeature -FeatureName AllowBastionHost -ProviderNamespace Microsoft.Network
    Register-AzResourceProvider -ProviderNamespace Microsoft.Network
}

While ($null -eq $installed) { 
    #$installed = Get-AzProviderFeature -ProviderNamespace Microsoft.Network | Where-Object -Property "FeatureName" -EQ "AllowBastionHost" 
    $installed = Get-AzResourceProvider -ProviderNamespace Microsoft.Network
    $isInstalled = $null -ne $installed
    Write-Host "Is installed: $isInstalled"
    Start-Sleep -Seconds 20 
}

Write-Host "Installation complete"
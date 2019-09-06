$installed = Get-AzProviderFeature -ProviderNamespace Microsoft.Network | Where-Object -Property "FeatureName" -EQ "AllowBastionHost" 

if ($null -eq $installed) {
    Register-AzProviderFeature -FeatureName AllowBastionHost -ProviderNamespace Microsoft.Network
    Register-AzResourceProvider -ProviderNamespace Microsoft.Network
}

While ($null -eq $installed) { 
    $installed = Get-AzProviderFeature -ProviderNamespace Microsoft.Network | Where-Object -Property "FeatureName" -EQ "AllowBastionHost" 
    $isInstalled = $null -ne $installed
    Write-Host "Is installed: $isInstalled"
    Start-Sleep -Seconds 20 
}

Write-Host "Installation complete"
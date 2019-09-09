[CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $SubscriptionId,
        [Parameter(Mandatory=$true)]
        [string]
        $NetworkWatcherRegion,
        [Parameter(Mandatory=$true)]
        [string]
        $NetworkSecurityGroupId,
        [Parameter(Mandatory=$true)]
        [string]
        $DiagnosticStorageAccountId,
        [Parameter(Mandatory=$true)]
        [string]
        $WorkspaceId,
        [Parameter(Mandatory=$true)]
        [string]
        $LogAnalyticsWorkspaceId,
        [Parameter(Mandatory=$true)]
        [string]
        $WorkspaceRegion
    )

try {
    $currentSubscriptionId = Get-AzContext | Select-Object "Subscription"

    if ($null -eq $currentSubscriptionId) {
        throw "Are you logged in? Please, make sure to run Login-AzAccount"
    }
    elseif ($null -ne $currentSubscriptionId -and `
            $currentSubscriptionId.Subscription.Id.ToString() -ne $SubscriptionId) {
        Set-AzContext -Subscription $SubscriptionId
    }
    else {
        Write-Host "No subscription switching is required."
    }

    $WorkspaceRegion = $WorkspaceRegion.Replace(' ', '').ToLower()
    $NetworkWatcherRegion = $NetworkWatcherRegion.Replace(' ', '').ToLower()

    $registered = Get-AzResourceProvider -ProviderNamespace Microsoft.Insights

    if ($null -eq $registered) {
        Register-AzResourceProvider -ProviderNamespace Microsoft.Insights
    }

    While ($null -eq $registered) {
        $registered = Get-AzResourceProvider -ProviderNamespace Microsoft.Insights
        $isRegistered = $null -ne $registered
        Write-Host "Is installed: $isRegistered"
        Start-Sleep -Seconds 20
    }

    Write-Host "Registration complete"

    $NW = Get-AzNetworkWatcher -ResourceGroupName NetworkWatcherRg -Name "NetworkWatcher_$NetworkWatcherRegion"

    #Configure Version 2 FLow Logs with Traffic Analytics Configured
    Set-AzNetworkWatcherConfigFlowLog -EnableRetention $true -RetentionInDays 365 -NetworkWatcher $NW -TargetResourceId $NetworkSecurityGroupId -StorageAccountId $DiagnosticStorageAccountId -EnableFlowLog $true -FormatType Json -FormatVersion 2 -EnableTrafficAnalytics -WorkspaceResourceId $LogAnalyticsWorkspaceId -WorkspaceGUID $WorkspaceId -WorkspaceLocation $WorkspaceRegion | Out-Null
}
catch {
    throw $_
}

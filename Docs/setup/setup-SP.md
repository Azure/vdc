# Create a new Service Principal
From a PowerShell window logged into Azure, run the following PowerShell. 
$spDisplayName should have <YOURALIAS> replaced with an alias. (e.g. 'sp-josmith')

> Import-Module Az
>$spDisplayName = 'sp-<YOURALIAS>>
>$password = (New-Guid).guid
>$credentials = New-Object Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential -Property @{ StartDate=Get-Date; EndDate=Get-Date -Year 2024; Password=$password}
>$sp = New-AzAdServicePrincipal -DisplayName $spDisplayName -PasswordCredential $credentials
>
> Write-Warning "DisplayName: $($sp.DisplayName) (WRITE THIS DOWN)"
>
> Write-Warning "Password: $password (WRITE THIS DOWN)"
>
> Write-Warning "ApplicationId: $($sp.ApplicationId.guid) (WRITE THIS DOWN)" 
> 
> Write-Warning "ObjectId: $($sp.Id) (WRITE THIS DOWN)"
> 
> Write-Warning "TenantId: $((Get-AzContext).Tenant.Id) (WRITE THIS DOWN)"
> 
> Write-Warning "SubscriptionId $((Get-AzContext).Subscription.Id) (WRITE THIS DOWN)"

# Connect to Azure with your Service Princpal

> $pscredential = Get-Credential

Use `Application ID`  then `Password ID`

> Connect-AzAccount -ServicePrincipal -Credential $pscredential -TenantId <Tenant ID>

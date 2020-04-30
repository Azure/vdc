##### Replace values with environment variables for the toolkit.subscription.json file
$var = (Get-Content -Path .\Config\toolkit.subscription.json) | ConvertFrom-Json
$var.Comments = "ToolKit for creating a new Virtual Data Center"
$var.SubscriptionId = $ENV:SUBSCRIPTION_ID
$var.TenantId = $ENV:TENANT_ID
$var.Location = $ENV:AZURE_LOCATION
$var | ConvertTo-Json | Set-Content -Path .\Config\toolkit.subscription.json

##### Replace values with environment variables for the subscription.json file
$vdc = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$vdc.VDCVDI.SubscriptionId = $ENV:SUBSCRIPTION_ID
$vdc.VDCVDI.TenantId = $ENV:TENANT_ID
$vdc | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json

$SS = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$SS.SharedServices.SubscriptionId = $ENV:SUBSCRIPTION_ID
$SS.SharedServices.TenantId = $ENV:TENANT_ID
$SS | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json

$arti = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$arti.Artifacts.SubscriptionId = $ENV:SUBSCRIPTION_ID
$arti.Artifacts.TenantId = $ENV:TENANT_ID
$arti | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json

$onprem = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$onprem.OnPremises.SubscriptionId = $ENV:SUBSCRIPTION_ID
$onprem.OnPremises.TenantId = $ENV:TENANT_ID
$onprem | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json

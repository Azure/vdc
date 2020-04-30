
$var = (Get-Content -Path .\Config\toolkit.subscription.json) | ConvertFrom-Json
$var.Comments = "Cleaned up from deployment"
$var.SubscriptionId = "000000-000-0000-0000"
$var.TenantId = "00000-0000000-000000-0000-0"
$var.Location = "DUMMYVALUE"
$var | ConvertTo-Json | Set-Content -Path .\Config\toolkit.subscription.json
##### Replace values with environment variables for the subscription.json file
$vdc = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$vdc.VDCVDI.SubscriptionId = "000000-000-0000-0000"
$vdc.VDCVDI.TenantId = "000000-000-0000-0000"
$vdc | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json
$SS = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$SS.SharedServices.SubscriptionId = "000000-000-0000-0000"
$SS.SharedServices.TenantId ="000000-000-0000-0000"
$SS | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json
$arti = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$arti.Artifacts.SubscriptionId = "000000-000-0000-0000"
$arti.Artifacts.TenantId = "000000-000-0000-0000"
$arti | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json
$onprem = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$onprem.OnPremises.SubscriptionId = "000000-000-0000-0000"
$onprem.OnPremises.TenantId = "000000-000-0000-0000"
$onprem | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json

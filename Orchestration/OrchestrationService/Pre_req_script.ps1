Write-Host `n"Running the Pre-Req script for the VDC toolkit" -ForegroundColor Cyan
Write-Host `n"Setting Subscription ID and Tenant ID in the Config Files." -ForegroundColor Green

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
$SS.SharedServices.SubscriptionId = $ENV:HUB_SUB_ID
$SS.SharedServices.TenantId = $ENV:TENANT_ID
$SS | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json

$arti = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$arti.Artifacts.SubscriptionId = $ENV:HUB_SUB_ID
$arti.Artifacts.TenantId = $ENV:TENANT_ID
$arti | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json

$arti = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$arti.SPOKE.SubscriptionId = $ENV:SUBSCRIPTION_ID
$arti.SPOKE.TenantId = $ENV:TENANT_ID
$arti | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json
$onprem = (Get-Content -Path .\Environments\_Common\subscriptions.json) | ConvertFrom-Json
$onprem.OnPremises.SubscriptionId = $ENV:SUBSCRIPTION_ID
$onprem.OnPremises.TenantId = $ENV:TENANT_ID
$onprem | ConvertTo-Json | Set-Content -Path .\Environments\_Common\subscriptions.json


Write-Host `n"Checking password randomization" -ForegroundColor Green

#### Check if random passwords are needed or if passwords are provided for the VM admin accounts and the Active Directory Account

# Random Password Function
function Get-RandomPassword {
    $Alphabets = 'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
    $numbers = 0..9
    $specialCharacters = '~,!,@,#,$,%,^,&,*,(,),?,\,/,_,-,=,+'
    $array = @()
    $counter= Get-Random -Minimum 5 -Maximum 7
    $array += $Alphabets.Split(',') | Get-Random -Count $counter
    $array[0] = $array[0].ToUpper()
    $array[-1] = $array[-1].ToUpper()
    $array += $numbers | Get-Random -Count $counter
    $array += $specialCharacters.Split(',') | Get-Random -Count $counter
    $password = ($array | Get-Random -Count $array.Count) -join "" 
    
    return $password #| ConvertTo-SecureString -AsPlainText -Force
}
    
### Check the VM password 
if (($null -eq $ENV:ADMIN_USER_PWD) -or ("" -eq $ENV:ADMIN_USER_PWD) -or ("Random" -eq $ENV:ADMIN_USER_PWD) ) {
    $ENV:ADMIN_USER_PWD = Get-RandomPassword
    Write-Host `n"Admin Password set for random" -ForegroundColor Green
}
else {
    Write-Host `n"Admin password was not randomized." -ForegroundColor Cyan
}
### Check the Active Directory (Domain Password)
if (($null -eq $ENV:DOMAIN_ADMIN_USER_PWD) -or ("" -eq $ENV:DOMAIN_ADMIN_USER_PWD) -or ("Random" -eq $ENV:DOMAIN_ADMIN_USER_PWD) ) {
    $ENV:DOMAIN_ADMIN_USER_PWD = Get-RandomPassword
    Write-Host `n"Domain Password set for random" -ForegroundColor Green
}
else{
    Write-Host `n"Domain Password was not randomized." -ForegroundColor Cyan
}


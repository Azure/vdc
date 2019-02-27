[CmdletBinding()]
param(
    [Parameter(Mandatory=$True)]
    [string]$NewDnsZone,
    [Parameter(Mandatory=$True)]
    [string]$Domain,
    [Parameter(Mandatory=$True)]
    [string]$KdcMasterHostname,
    [Parameter(Mandatory=$True)]
    [string]$KdcSlaveHostname,
    [Parameter(Mandatory=$True)]
    [string]$KerberosDbPassword
)
$lower_domain = $Domain.ToLower()
ksetup /addkdc $NewDnsZone $KdcMasterHostname + '.' + $NewDnsZone.ToLower()
ksetup /addkdc $NewDnsZone $KdcSlaveHostname + '.' + $NewDnsZone.ToLower()
netdom trust $NewDnsZone /Domain:$lower_domain /add /realm /passwordt:$KerberosDbPassword
ksetup /SetEncTypeAttr $NewDnsZone AES256-CTS-HMAC-SHA1-96 AES128-CTS-HMAC-SHA1-96
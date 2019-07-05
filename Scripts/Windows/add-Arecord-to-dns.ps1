[CmdletBinding()]
param(
    [Parameter(Mandatory=$True)]
    [string]$HostName,
    [Parameter(Mandatory=$True)]
    [string]$IPAddress,
    [Parameter(Mandatory=$True)]
    [string]$DnsZone
)
Add-DnsServerResourceRecordA -Name $HostName -ZoneName $DnsZone -AllowUpdateAny -IPv4Address $IPAddress -TimeToLive 00:01:00
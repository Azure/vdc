[CmdletBinding()]
param(
    [Parameter(Mandatory=$True)]
    [string]$DnsZone
)

Add-DnsServerPrimaryZone -Name $DnsZone -ReplicationScope Forest -DynamicUpdate Secure -PassThru
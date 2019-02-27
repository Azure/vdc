[CmdletBinding()]
param(
    [Parameter(Mandatory=$True)]
    [string]$CloudSite
)
New-ADReplicationSite $CloudSite
New-ADReplicationSiteLink "$CloudSite-SiteLink" -SitesIncluded Default-First-Site-Name,$CloudSite -Cost 100 -ReplicationFrequencyInMinutes 15 -InterSiteTransportProtocol IP
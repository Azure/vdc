[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [int]$Sleep

)
Start-Sleep -Seconds $Sleep
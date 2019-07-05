[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$TestString

)
Write-Host "$TestString"
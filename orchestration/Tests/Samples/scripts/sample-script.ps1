[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [string] $FirstParameter,
    [Parameter(Mandatory=$false)]
    [string] $SecondParameter,
    [Parameter(Mandatory=$false)]
    [string] $ThirdParameter
)

if(![string]::IsNullOrEmpty($SecondParameter)) {
    Write-Output "$SecondParameter";
}
else {
    Write-Output "pwsh";
}
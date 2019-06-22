[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]
    $ResourceGroupName,
    [Parameter(Mandatory=$false)]
    [string]
    $ResourceGroupLocation,
    [Parameter(Mandatory=$false)]
    [switch]
    $TearDownResourceGroup,
    [Parameter(Mandatory=$false)]
    [switch]
    $SetupResourceGroup
)

$defaultValidationResourceGroupName = "vdc-validation-rg";
$defaultValidationResourceGroupLocation = "West US";

Function Get-ValidationResourceGroup() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $ResourceGroupName
    )
    # Is a resource group name passed?
    if($null -ne $resourceGroupName) {
        # Get the resource group by name
        return `
            Get-AzResourceGroup `
                -Name $resourceGroupName `
                -ErrorAction SilentlyContinue;
    }
    else {
        return $null;
    }
}

Function SetupResourceGroup() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string] $ResourceGroupName,
        [Parameter(Mandatory=$false)]
        [string] $ResourceGroupLocation
    )
    # Try to get the validation resource group by
    # name
    $existingValidationResourceGroup = `
        Get-ValidationResourceGroup `
            -ResourceGroupName $ResourceGroupName;

    # Does the resource group exists?
    if($null -eq $existingValidationResourceGroup) {
        # Create the resource group
        return `
            New-AzResourceGroup `
                -Name $ResourceGroupName `
                -Location $ResourceGroupLocation;
    }
    else {
        return `
            $existingValidationResourceGroup;
    }
}

Function TearDownResourceGroup() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string] $ResourceGroupName
    )
    # Try to get the validation resource group by
    # name
    $existingValidationResourceGroup = `
        Get-ValidationResourceGroup `
            -ResourceGroupName $ResourceGroupName;

    # Does the resource group exists?
    if($null -ne $existingValidationResourceGroup) {
        # Delete the resource group
        Remove-AzResourceGroup `
            -Name $ResourceGroupName `
            -Force `
            -Confirm:$false;
    }
}

if([string]::IsNullOrEmpty($ResourceGroupName)) {
    $ResourceGroupName = $defaultValidationResourceGroupName;
}
if([string]::IsNullOrEmpty($ResourceGroupLocation)) {
    $ResourceGroupLocation = $defaultValidationResourceGroupLocation;
}

if($TearDownResourceGroup.IsPresent) {
    # Call function to tear down the validation resource group
    TearDownResourceGroup `
        -ResourceGroupName $ResourceGroupName;
}
elseif ($SetupResourceGroup.IsPresent) {
    # Call function to setup the validation resource group
    SetupResourceGroup `
        -ResourceGroupName $ResourceGroupName `
        -ResourceGroupLocation $ResourceGroupLocation;
}
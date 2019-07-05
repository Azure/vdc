[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string] 
    $SubscriptionName,
    [Parameter(Mandatory=$true)]
    [string] 
    $Location,
    [Parameter(Mandatory=$false)]
    [string] 
    $SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string] 
    $TenantId,
    [Parameter(Mandatory=$false)]
    [string] 
    $ManagementGroupName,
    [Parameter(Mandatory=$true)]
    [string]
    $OfferType
)

Function New-Subscription {
    param (
        [Parameter(Mandatory=$true)]
        [string] $SubscriptionName
    )

    try {
        # Get the Enrollment Account's Object Id for creating 
        # new subscription
        $enrollmentAccount = (Get-AzEnrollmentAccount);

        if($null -ne $enrollmentAccount -and $enrollmentAccount.Count -gt 0) {
            $enrollmentAccountObjectId = $enrollmentAccount[0].ObjectId
        }
        else {
            Write-Error "No enrollment account";
        }

        # Create a New Subscription
        return (New-AzSubscription -OfferType $OfferType -Name $SubscriptionName -EnrollmentAccountObjectId $enrollmentAccountObjectId).SubscriptionId;
    }
    Catch {
        Write-Error "An exception occurred when trying to create a new subscription";
        Write-Error $_;
        Throw $_;
    }
}

Function Add-SubscriptionToManagementGroup {
    param (
        [Parameter(Mandatory=$true)]
        [string] $ManagementGroupName,
        [Parameter(Mandatory=$true)]
        [Guid] $SubscriptionId
    )

    try {
        # Check if the Management Group exists
        $managementGroup = Get-AzManagementGroup -GroupName $ManagementGroupName -ErrorAction SilentlyContinue;

        if($null -eq $managementGroup) {

            # Create a new Management Group since it does
            # not exists
            New-AzManagementGroup -GroupName $ManagementGroupName;

            # Add the Subscription to the Management Group
            # that was created in the previous step
            New-AzManagementGroupSubscription -GroupName $ManagementGroupName -SubscriptionId $SubscriptionId;
        }
        else {

            # Add the Subscription to an existing Resource
            # Group
            New-AzManagementGroupSubscription -GroupName $ManagementGroupName -SubscriptionId $SubscriptionId;
        }
    }
    Catch {
        Write-Error "An exception occurred when trying to associate a subscription to management group";
        Write-Error $_;
        Throw $_;
    }
}

# Check if a Subscription Id is provided. If a Subscription
# Id is not provided, create a new subscription.
if([string]::IsNullOrEmpty($SubscriptionId)) {

    $tenant = Get-AzTenant -TenantId  $TenantId;
    
    Set-AzContext -Tenant $tenant;

    # If no Subscription Id is passed, then create
    # a new Subscription
    $SubscriptionId = New-Subscription -SubscriptionName $SubscriptionName;

}
# If a Subscription Id is provided, use the subscription
else {

    # If a subscription Id is passed, then check if the 
    # subscription exists
    $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId -TenantId $TenantId;

    # If the subscription does not exists, throw exception
    if($null -ne $subscription) {
        Throw "Subscription referenced by Id $SubscriptionId does not exists";
    }
}

if (![string]::IsNullOrEmpty($ManagementGroupName)) {
    # After creating / check for the subsciption by Id, proceed with associating 
    # the subscription to management group.
    Add-SubscriptionToManagementGroup -ManagementGroupName $ManagementGroupName -SubscriptionId $SubscriptionId;
}

return @{
    SubscriptionId = $SubscriptionId
    TenantId = $TenantId
    Location = $Location
}
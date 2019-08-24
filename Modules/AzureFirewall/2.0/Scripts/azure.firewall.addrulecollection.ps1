[CmdletBinding()]
param(
    [Parameter(Mandatory=$True)]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$True)]
    [string]$AzureFirewallName,
    [Parameter(Mandatory=$True)]
    [string]$AzureFirewallResourceGroup,
    [Parameter(Mandatory=$True)]
    [array]$RuleCollections,
    [Parameter(Mandatory=$True)]
    [string]$RuleType
)


Function ConvertTo-HashTable() {
    [CmdletBinding()] 
    Param(
        [Parameter(Mandatory=$false)]
        $InputObject
    )

    if($InputObject) {
        # Convert to string prior to converting to 
        # hashtable
        $objectString = `
            ConvertTo-Json `
                -InputObject $InputObject `
                -Depth 100;

        # Convert string to hashtable and return it
        return `
            ConvertFrom-Json `
                -InputObject $objectString `
                -AsHashtable;
    }
    else {
        return $null;
    }
}

# Construct the Resource Id for Azure Firewall using subscription id, resource group name and azure firewall name
$azureFirewallId = "/subscriptions/$SubscriptionId/resourceGroups/$AzureFirewallResourceGroup/providers/Microsoft.Network/azureFirewalls/$AzureFirewallName";

# Get the current state of the Azure Firewall from Graph
$azfw = Search-AzGraph -Query "where id == '$azureFirewallId'";

if($null -ne $azfw) {

    # Convert AzureFirewall object to hashtable
    $azfw = ConvertTo-HashTable -InputObject $azfw;

    # Convert Rule Collection passed to this script into hashtable
    $RuleCollections= ConvertTo-HashTable -InputObject $RuleCollections;

    if($RuleType -eq "application") {
        $RuleCollectionType = "applicationRuleCollections";
    }
    elseif($RuleType -eq "network") {
        $RuleCollectionType = "networkRuleCollections"
    }
    else {
        Throw "This Rule Type is not supported by this script.";
    }

    $RuleCollections | ForEach-Object {

        $RuleCollection = $_;

        # Retrive the specific application rule collection by name from the Azure Firewall
        $currentRuleCollection = `
            $azfw.properties.$RuleCollectionType | `
                Where-Object {
                    $_.name -eq $RuleCollection.name 
                };

        # Branch based on whether the Rule Collection already exists or not. 
        # If it already exists, check the rules and update it if necessary.
        # If it doesn't already exists, add the new rule collection.
        if($null -ne $currentRuleCollection) {
            Write-Host "Found";
            # Get the index of the application rule collection
            $indexOfRuleCollection = [array]::indexOf($azfw.properties.$RuleCollectionType, $currentRuleCollection);

            # Empty the previous Rules list and reset it to the new Rules list
            $azfw.properties.$RuleCollectionType[$indexOfRuleCollection].properties.rules = $RuleCollection.properties.rules;
        }
        else {
            Write-Host "Not Found";
            $azfw.properties.$RuleCollectionType += $RuleCollection;
        }
    }

    # Print out the Rule Collection as output.
    return  $azfw.properties.$RuleCollectionType;
}
else {

    Throw "Firewall named $AzureFirewallName does not exists";
}
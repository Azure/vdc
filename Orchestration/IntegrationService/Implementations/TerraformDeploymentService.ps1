Class TerraformDeploymentService: IDeploymentService {

    [hashtable] ExecuteDeployment([string] $tenantId, `
                                  [string] $subscriptionId, `
                                  [string] $resourceGroupName, `
                                  [string] $deploymentTemplate, `
                                  [string] $deploymentParameters, `
                                  [string] $location) {
        $fileName = "$([Guid]::NewGuid().ToString()).tf";

        try {
            # Run terraform init
            # Create a temp file based on deploymentTemplate
            # Run terraform apply --auto-approve

            $deploymentTemplate > $fileName;

            Invoke-Command -ScriptBlock {
                terraform init
            }

            Invoke-Command -ScriptBlock {
                terraform apply --auto-approve
            }
            
            return @{
                DeploymentId = $null
                DeploymentName = $null
                ResourceStates = $null
                ResourceIds = $null
                DeploymentOutputs = $null
                TenantId = $tenantId
                SubscriptionId = $subscriptionId
                ResourceGroupName = $resourceGroupName
                DeploymentTemplate = $null
                DeploymentParameters = $null
            }
        }
        catch {
            throw "An exception ocurred while running a Terraform deployment";
        }
        finally {
            # Delete the temp file
            Remove-Item -Path $fileName -ErrorAction SilentlyContinue;
        }
    }

    [void] ExecuteValidation([string] $tenantId, `
                            [string] $subscriptionId, `
                            [string] $resourceGroupName, `
                            [string] $deploymentTemplate, `
                            [string] $deploymentParameters, `
                            [string] $location) {
        Write-Debug "No validation";
    }

    [void] CreateResourceGroup([string] $resourceGroupName,
                               [string] $location) {
        Write-Debug "No subscription created";
    }

    [void] SetSubscriptionContext([guid] $subscriptionId,
                                  [guid] $tenantId) {
        Write-Debug "No subscription context switched";
    }
}
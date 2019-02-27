Post-deployment subscription policy updates
===========================================

**Required role: SecOps**

Predefined policies are enforced at the subscription and resource group level as
part of VDC automation resource deployment. These policies are defined in
standard [Azure Resource Manager Policy
json](https://docs.microsoft.com/azure/azure-policy/json-samples) format
and are stored in the module's *policies* folder in a structure corresponding
to the management group or subscription. <br/> To assign a  built-in policy to a subscription, you must include **policyDefinitionId** and **name** properties as a policy object in your [policy file](../modules/policies/subscription/1.0/arm.policies.json). <br/> To assign management group policies, you must include **policyDefinitionId** and **name** properties as a policy object in your [policy file](../modules/policies/management-group/1.0/arm.policies.json). <br/>  If your organization has different
policy requirements than what the VDC automation toolkit assumes, you can update
these files to modify the policies.

For situations where you need to update policy after deploying resources, the
automation toolkit includes the script file
[policy\_assignment.py](../policy_assignment.py).
To use this script, open a terminal/command line, navigate to the root of the VDC Toolkit folder, and then run the following command:

[Linux/OSX]

>   *python3 policy\_assignment.py --configuration-file-path {path to your deployment configuration file} -file {path to your policy file} --management-group-id {your management group id} -sid {your
>   subscription id} -rg {name of resource group}*

[Windows]

>   *py policy\_assignment.py --configuration-file-path {path to your deployment configuration file} -file {path to your policy file} --management-group-id {your management group id} -sid {your
>   subscription id} -rg {name of resource group}*

[Docker]

>   *python policy\_assignment.py --configuration-file-path {path to your deployment configuration file} -file {path to your policy file} --management-group-id {your management group id} -sid {your
>   subscription id} -rg {name of resource group}*

There are several arguments that need to be passed to apply policies.

| **Argument**                       | **Description**                                                                                                                                                                    |
|------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| \-file [Required]       | Path to the policy file you want to apply.                                                                                                                                         |
| \--management-group-id [Optional] | If specified, the policies are assigned to a management group. This value takes precedence over subscription-id and resource-group.                                                                                                                        |
| \-sid [Optional] | Specifies the subscription id where the policies are applied.                                                                                                                         |
| \-rg --resource-group [Optional]   | Specifies a resource group target for applying policy. If specified, policy is only applied to that resource group. |


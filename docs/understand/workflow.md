# Common workflow

This is an example of how the tools in the Azure Virtual Datacenter Automation Toolkit are generally used.

The high-level steps are:

1. Set up a subscription
2. Assign custom roles to the subscription
3. Deploy an archetype
4. Apply additional policies as needed

## Setting up a subscription

You can create a subscription using [`subscription.py`](../reference/script-subscription.adoc).
If you are _not_ using management groups, then you can proceed to [assigning custom roles](#Assigning-custom-roles).

Otherwise, you can create a management group and then associated it with the new subscription using `subscription.py`.

NOTE: These are separate invocations of `subscription.py` using different commands that are explained in the reference document. One command creates a subscription, another command creates a management group, and a third command associates the subscription and the management group.

You can optionally assign policies to the newly created management group using [`policy-assignment.py`](../reference/script-policy-assignemnt.adoc).

## Assigning custom roles

The custom roles are defined in the [`roles/aad.roles.json`](../../roles/aad.roles.json) file. These roles are assigned to a new subscription using [`role-creation.py`](../reference/script-role-creation.adoc).

## Deploying archetypes

An archetype can then be deployed into the new subscription using [`vdc.py`](../reference/script-vdc). This script will assign policies at both the subscription and resource group level. These policies include the ones specified in [`modules/policies/subscription/1.0/arm.policies.json`](../../modules/policies/subscription/1.0/arm.policies.json), assigned at the subscription level, and the policies specified in the the archetype's modules, assigned at the resource group level.

## Assigning additional policies

You can apply policies to the subscription or management group after an archetype is deployed using [`policy-assignment.py`](../reference/script-policy-assignment.adoc). Example policies are located in the [`modules/policies`](../../modules/policies/) folder.

## Next steps

Learn about the [environment types](environment-types.md) in the toolkit.

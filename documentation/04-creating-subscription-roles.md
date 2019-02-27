# Creating subscription roles 

**Required role: Subscription owner**

Before deploying any resources to your subscription, you first need to create
roles and permissions for team members. The default [VDC roles are
discussed](02-how-vdc-automation-works.md#deployment-types) elsewhere in this guide, and you can modify these
by editing the
[roles/aad.roles.json](../roles/aad.roles.json)
file.

The automation toolkit contains the
[role\_creation.py](../role_creation.py)
script to automate the creation of these roles. To use this script, open a terminal/command line, navigate to the root of the VDC Toolkit folder, and then run the following command:

[Linux/OSX]

>   *python3 role\_creation.py -r {path to your role file} -sid {your
>   subscription id}*

[Windows]

>   *py role\_creation.py -r {path to your role file} -sid {your subscription
>   id}*

## Arguments

You must pass two required arguments to create roles.

| **Argument**                       | **Description**                                                                                                                                                               |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| \-r <br>--roles-file <br>[Required]        | Path to your roles file. Default path is [roles/aad.roles.json](../roles/aad.roles.json). |
| \-sid <br>--subscription-id <br>[Required] | Specifies the subscription identifier where the script defines roles.                                                                                                         |

After these roles are created in the subscription, you can assign users as
appropriate before proceeding with the deployment of VDC resources.

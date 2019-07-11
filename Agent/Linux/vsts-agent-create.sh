#!/bin/bash

AZDO_URL=$1
PAT=$2
VSTS_POOL=$3
AGENT_NAME=$4

CLOUD_INIT='#cloud-config
runcmd:
 - [ echo, "Configuring the Agent ..."   ]
 - [ /agent/bin/Agent.Listener, configure, --unattended, --url, "AZDO_URL", --auth, pat, --token, PAT, --pool, VSTS_POOL, --agent, AGENT_NAME, --acceptTeeEula]
 - [ echo, "Agent successfully configured" ]
 - [ chmod, a+rwx, /agent/_diag ]
 - [ chmod, a+rwx, /agent/.credentials_rsaparams ]
 - [ cd, /agent]
 - [ sudo, ./svc.sh, install ]
 - [ sudo, ./svc.sh, start]
'
CLOUD_INIT=${CLOUD_INIT/AZDO_URL/$AZDO_URL}
CLOUD_INIT=${CLOUD_INIT/PAT/$PAT}
CLOUD_INIT=${CLOUD_INIT/VSTS_POOL/$VSTS_POOL}
CLOUD_INIT=${CLOUD_INIT/AGENT_NAME/$AGENT_NAME}

RESOURCE_GROUP_NAME='vdc-azuredevops-agents-rg'
NSG_NAME=$AGENT_NAME'NSG'

echo "Creating VM Agent from Image ..."
az vm create \
  --resource-group $RESOURCE_GROUP_NAME \
  --location westus \
  --name $AGENT_NAME \
  --public-ip-address "" \
  --vnet-name ubuntu-agent-rg-vnet \
  --subnet default \
  --image ubuntu-self-hosted-agent \
  --custom-data "$CLOUD_INIT" \
  --admin-username azureuser \
  --generate-ssh-keys \
  --verbose

echo "Removing default ssh access NSG rule"
az network nsg rule delete \
  --resource-group $RESOURCE_GROUP_NAME \
  --nsg-name $NSG_NAME \
  --name 'default-allow-ssh'

echo "Adding NSG rule to deny ssh access from all sources.
You can modify this later for your specific IP. Look for NSG
rule by name 'ssh'.
"
az network nsg rule create \
  --resource-group $RESOURCE_GROUP_NAME \
  --nsg-name $NSG_NAME \
  --name 'ssh' \
  --access Deny \
  --direction Inbound \
  --priority 900 \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "*"
  
  az logout
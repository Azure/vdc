#!/bin/bash

AZDO_URL=$1
PAT=$2
VSTS_POOL=$3
AGENT_NAME="vsts-ubuntu-agent"

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

az vm create \
  --resource-group vsts-agent-rg \
  --location westus \
  --name $AGENT_NAME \
  --vnet-name ubuntu-agent-rg-vnet \
  --subnet default \
  --image ubuntu-self-hosted-agent \
  --custom-data "$CLOUD_INIT" \
  --admin-username azureuser \
  --generate-ssh-keys \
  --verbose
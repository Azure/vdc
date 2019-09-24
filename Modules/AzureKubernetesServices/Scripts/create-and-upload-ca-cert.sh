#!/usr/bin/env bash

DIR=$(dirname $0)

PGM=$(basename $0)

# Names set in set-environment-vars.sh:
# VNET
# KEY_VAULT_NAME
# PRIVATE_DNS_ZONE
# CA_CERT_KEY_NAME
# CA_NAME

KEY_VAULT_NAME=$1
CA_CERT_KEY_NAME=$2
CA_NAME=$3

# keyvault appears to need pkc8
KEY_CONTENT=$(openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:2048 | \
    openssl pkcs8 -topk8 \
    -nocrypt \
    -inform PEM \
    -outform PEM
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: error creating private key:$KEY_CONTENT"
   exit 1
fi

# this config section is needed to support 
# getting basic constraint for CA:TRUE 
# added
CONFIG="
[req]
distinguished_name=dn
[ dn ]
[ ext ]
basicConstraints=CA:TRUE,pathlen:0
"

CA_CERT_CONTENT=$(openssl \
    req -new \
    -subj "/CN=$CA_NAME" \
    -key <(echo "$KEY_CONTENT") \
    -config <(echo "$CONFIG") \
    -extensions ext \
    -sha256 -days 365 -nodes -x509 -out /dev/stdout
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: error creating ca cert:$CA_CERT_CONTENT"
   exit 1
fi

# need to concatenate key and cert as PEM
CERT_WITH_KEY=$(echo -e "${KEY_CONTENT}\n${CA_CERT_CONTENT}")

echo "$PGM: Checking cert with key ..."
CHECK_CERT_RESULT=$(
  openssl x509 -text -noout -in <(echo "$CERT_WITH_KEY" 2>&1 ) 
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Verifying cert failed:$CHECK_CERT_RESULT"
   exit 1
fi
echo "$PGM: CERT is valid"

# upload cert with key to keyvault
echo "$PGM: importing CA certificate to keyvault ..."
IMPORT_RESULT=$(az keyvault certificate import \
    --name $CA_CERT_KEY_NAME \
    --vault-name $KEY_VAULT_NAME \
    --file <(echo "$CERT_WITH_KEY")
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: upload cert failed:$IMPORT_RESULT"
   exit 1
fi
echo "$PGM: import complete"

#!/usr/bin/env bash
DIR=$(dirname $0)

PGM=$(basename $0)

# Names set in set-environment-vars.sh:
KEY_VAULT_NAME=$3
CA_CERT_NAME=$4

#
# Subject Alternative Names (SAN) need to be comma 
# separated list type as prefix. e.g.
# DNS:www.helm,DNS:helm,IP:127.0.0.1,IP:10.0.1.100
#
if [[ "$#" -ne 4 ]] && [[ "$#" -ne 5 ]];then
   echo "$PGM usage: $PGM environment cert-name [SAN]"
   exit 1
fi
CERT_NAME=$2

SAN=
if [[ "$5" != "" ]];then
  echo "$PGM: Using Subject Alternative Name (SAN) parameter :$5"
  SAN=$5
fi

echo "$PGM: Getting CA key:$CA_CERT_NAME from vault:$KEY_VAULT_NAME .."
CA_KEY_PAIR=$( \
  az keyvault secret download \
    --name $CA_CERT_NAME \
    --vault-name $KEY_VAULT_NAME \
    --file /dev/stdout
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Error getting CA Cert:$CA_KEY_PAIR"
   exit 1
fi

echo "$CA_KEY_PAIR"
echo "$PGM: Checking CA cert ..."
CHECK_KEY_PAIR_RESULT=$(
  openssl x509 -text -noout -in <(echo "$CA_KEY_PAIR") 
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Verifying cert failed:$CHECK_KEY_PAIR_RESULT"
   exit 1
fi
echo "$PGM: CA cert is ok"
# extract the cert and private key
# need these to be separate as tyring to pass
# keypair environment vars as input files does
# not work with openssl x509 command
echo "$PGM: Extracting keypair parts ..."
CA_CERT=$(openssl x509 \
  -outform pem \
  -in <(echo "$CA_KEY_PAIR") \
  -out /dev/stdout)

CA_KEY=$(openssl pkey \
  -in <(echo "$CA_KEY_PAIR") \
  -out /dev/stdout)

# create the private key and convert to pkcs8 format
# TODO: confirm with keyvault that we need pkcs8
echo "$PGM: Creating private key for $CERT_NAME ..."
PK=$( \
  openssl genpkey \
    -algorithm RSA \
    -pkeyopt rsa_keygen_bits:2048 | \
  openssl pkcs8 -topk8 \
    -nocrypt \
    -inform PEM \
    -outform PEM
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Error creating private key:$PK"
   exit 1
fi

CONFIG_PARM=
if [[ "$SAN" != "" ]];then
  SUBJECT_ALT_NAME="subjectAltName = DNS:$CERT_NAME,$SAN"
fi

#TODO: see what other properties/usage flags are needed
CONFIG_FILE=$(cat <<EOF
[req]
prompt = no
distinguished_name = dn
req_extensions = req_ext

[dn]
CN = $CERT_NAME

[req_ext]
basicConstraints = CA:FALSE
$SUBJECT_ALT_NAME
EOF
)

# Create CSR
echo "$PGM: Creating CSR ..."
CSR=$(openssl req \
  -new \
  -config <(echo "$CONFIG_FILE") \
  -sha256 \
  -key <(echo "$PK") \
  -subj "/CN=$CERT_NAME" \
  -out /dev/stdout
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Error creating CSR:$CSR"
   exit 1
fi
echo "$PGM: Checking CSR ..."
CHECK_CSR_RESULT=$(
  openssl req -verify -text -noout -in <(echo "$CSR") 2>&1
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "Verifying CSR failed:$CHECK_CSR_RESULT"
   exit 1
fi
echo "$PGM: CSR is valid"

echo "$PGM: Creating cert"
CERT=$(openssl x509 \
  -req \
  -days 365 \
  -CA <(echo "$CA_CERT") \
  -set_serial $(date +%s)$((1 + RANDOM % 1000)) \
  -CAkey <(echo "$CA_KEY") \
  -in <(echo "$CSR") \
  -extfile <(echo "$CONFIG_FILE") \
  -extensions req_ext \
  -out /dev/stdout
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Error creating Cert:$CERT"
   exit 1
fi

echo "$PGM: Checking cert ..."
CHECK_CERT_RESULT=$(
  openssl x509 -text -noout -in <(echo "$CERT") 2>&1 
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Verifying cert failed:$CHECK_CERT_RESULT"
   exit 1
fi
echo "$PGM: CERT is valid"

# upload cert to keyvault
# need to concatenate the key and cert into PEM
echo "$PGM: Uploading certificate ..."
UPLOAD=$( \
  az keyvault certificate import \
    --name $CERT_NAME \
    --vault-name $KEY_VAULT_NAME \
    --file <(echo -e "${PK}\n${CERT}" 2>&1)
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: upload cert failed:$UPLOAD"
   exit 1
fi
echo "$PGM: Upload complete"

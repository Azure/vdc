#!/usr/bin/env bash

DIR=$(dirname $0)

PGM=$(basename $0)

ENV_NAME=$1
KEY_VAULT_NAME=$3
CLUSTER_NAME=$4
CLUSTER_RG=$5
CA_CERT_KEY_NAME=$6

if [[ -z $2 ]];then
  echo "$PGM: usage environment target-namespace"
  exit 1
fi
TARGET_NAMESPACE=$2
echo "$PGM: Starting create of tiller instance for namespace:$TARGET_NAMESPACE"
# import functions
. $DIR/create-tiller-enabled-namespace.sh

# temp directory
MY_TEMPDIR=$(mktemp -d)
rc=$?
if [[ $rc -ne 0 ]];then
  echo "$PGM: Error creating temp file:$MY_TEMPDIR"
  exit 1
fi
function cleanup {
  echo "$PGM: Removing tmp dir $MY_TEMPDIR ..."; 
  rm -rf $MY_TEMPDIR; 
  echo "$PGM: Done removing tmp dir"
} 
trap cleanup EXIT

#
# Create certificates (identities for helm/tiller)
# 
# If the name is tiller its assumed to be a global
# instance for the cluster, otherwise
# the namespace becomes <namespace>-tiller/helm for
# a namespace scoped tiller instance
#
TILLER_CN=tiller
HELM_CN=helm
TILLER_NAMESPACE=$TILLER_CN
if [[ $TARGET_NAMESPACE != "tiller" ]];then
    HELM_CN=${TARGET_NAMESPACE}-$HELM_CN
    TILLER_CN=${TARGET_NAMESPACE}-$TILLER_CN
    TILLER_NAMESPACE=$TILLER_CN
fi
echo "$PGM: Creating helm cert with CN:$HELM_CN"
$DIR/../aks/create-sign-w-x509-and-upload-cert.sh $ENV_NAME $HELM_CN $KEY_VAULT_NAME $CA_CERT_KEY_NAME
echo "$PGM: Creating tiller cert with CA:$TILLER_CN"
$DIR/../aks/create-sign-w-x509-and-upload-cert.sh $ENV_NAME $TILLER_CN $KEY_VAULT_NAME $CA_CERT_KEY_NAME "IP:127.0.0.1"
# local names for cert/key files
# the names match default names searched for in $HELM_HOME by helm when using --tls
CA_CERT_FILE=$MY_TEMPDIR/ca.pem
TILLER_CERT_FILE=$MY_TEMPDIR/cert.pem
TILLER_KEY_FILE=$MY_TEMPDIR/key.pem

#
# Get kubernetes admin credentials
# 
KUBECONFIG_FILE=$MY_TEMPDIR/config
GET_CREDS_RESULT=$(az aks get-credentials --admin -n $CLUSTER_NAME -g $CLUSTER_RG --file $KUBECONFIG_FILE)
rc=$?
if [[ $rc -ne 0 ]];then
  echo "$PGM: Error getting admin credentials:$GET_CREDS_RESULT"
  exit 1
fi
echo "$PGM: Using temp file:$KUBECONFIG_FILE for kubeconfig"

#
# get the CA and tiller/helm certs from key vault
#
echo "$PGM: Getting CA cert $CA_CERT_KEY_NAME from key vault:$KEY_VAULT_NAME"
CA_CERT_DOWNLOAD=$(
  az keyvault certificate download \
  --name $CA_CERT_KEY_NAME \
  --vault-name $KEY_VAULT_NAME \
  -f $CA_CERT_FILE 2>&1 )
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Error downloading CA Cert:$CA_CERT_DOWNLOAD"
   exit 1
fi

echo "$PGM: Getting tiller keypair"
TILLER_KEY_PAIR=$( \
  az keyvault secret download \
    --name $TILLER_CN \
    --vault-name $KEY_VAULT_NAME \
    --file /dev/stdout
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Error getting tiller key pair:$TILLER_KEY_PAIR"
   exit 1
fi
#
# check that the certs are ok
#
echo "$PGM: Checking tiller key pair ..."
CHECK_TILLER_KEY_PAIR_RESULT=$(
  openssl x509 -text -noout -in <(echo "$TILLER_KEY_PAIR") 
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Verifying cert failed:$CHECK_TILLER_KEY_PAIR_RESULT"
   exit 1
fi
echo "$PGM: Tiller key pair is ok ..."

#
# extract the cert and private key
#
echo "$PGM: Extracting keypair parts ..."
TILLER_CERT_CONTENT=$(openssl x509 \
  -outform pem \
  -in <(echo "$TILLER_KEY_PAIR") \
  -out $TILLER_CERT_FILE 2>&1)

TILLER_KEY_CONTENT=$(openssl pkey \
  -in <(echo "$TILLER_KEY_PAIR") \
  | openssl rsa -out $TILLER_KEY_FILE 2>&1)


# see https://github.com/helm/helm/blob/master/docs/securing_installation.md
# use temp dir as helm reads from files twice so won't work with processes substitution
DRY_RUN=
#DRY_RUN="--dry-run"
DEBUG=
#DEBUG="--debug"

# 
# Create the tiller namespace
#
createTillerNamespace $TARGET_NAMESPACE $KUBECONFIG_FILE 
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: Error creating tiller enabled namespace:$TARGET_NAMESPACE"
   exit 1
fi

# Initialize 
HELM_INIT_RESULT=$(KUBECONFIG=$KUBECONFIG_FILE helm init \
$DRY_RUN \
$DEBUG \
--override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' \
--tiller-namespace ${TILLER_NAMESPACE} \
--service-account tiller \
--home $MY_TEMPDIR \
--tiller-tls \
--tiller-tls-verify \
--tiller-tls-cert "$TILLER_CERT_FILE" \
--tiller-tls-key "$TILLER_KEY_FILE" \
--tls-ca-cert "$CA_CERT_FILE"
)
rc=$?
if [[ $rc -ne 0 ]];then
   echo "$PGM: helm init returned error:$HELM_INIT_RESULT"
   exit 1
fi
echo "$PGM: $HELM_INIT_RESULT"

# 
# Wait for tiller deployment to complete
# If timeout is exceeded, script exits with exit code 1 and terminates deployment
#
TILLER_COMPLETE='deployment "tiller-deploy" successfully rolled out'
TILLER_STATUS=$(kubectl rollout status deployment/tiller-deploy --kubeconfig $KUBECONFIG_FILE -n ${TILLER_NAMESPACE})

echo "$PGM: waiting for tiller to deploy in namespace: $TILLER_NAMESPACE"
COUNTER=0
while true; do
  if [[ "$TILLER_STATUS" == "$TILLER_COMPLETE" ]];then
    echo "$PGM: tiller deployed and in Ready state"
    exit 0
  elif [[ $COUNTER -eq "24" ]];then
    echo "$PGM: tiller deployment timeout exceeded"
    exit 1
  else
    sleep 5
    TILLER_STATUS=$(kubectl rollout status deployment/tiller-deploy --kubeconfig $KUBECONFIG_FILE -n ${TILLER_NAMESPACE})
    COUNTER=$[$COUNTER + 1]
  fi
done



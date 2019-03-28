STORAGE_RESOURCE_GROUP_NAME=$1
SUBSCRIPTION_ID=$2
INGRESS_FILE_SHARE_NAME=$3
INGRESS_FILE_PATH=$4
EGRESS_FILE_SHARE_NAME=$5
EGRESS_FILE_PATH=$6
INIT_CFG_FILE_PATH=$7


palo_alto_storage_account_name="$(az storage account list -g "${STORAGE_RESOURCE_GROUP_NAME}" --subscription ${SUBSCRIPTION_ID} --query [].name --output tsv)"
palo_alto_storage_account_key="$(az storage account keys list -g "${STORAGE_RESOURCE_GROUP_NAME}" --subscription ${SUBSCRIPTION_ID} --account-name ${palo_alto_storage_account_name} --query [0].value --output tsv)"

az storage file upload --account-key $palo_alto_storage_account_key --account-name $palo_alto_storage_account_name --share-name $INGRESS_FILE_SHARE_NAME --source $INGRESS_FILE_PATH
az storage file upload --account-key $palo_alto_storage_account_key --account-name $palo_alto_storage_account_name --share-name $INGRESS_FILE_SHARE_NAME --source $INIT_CFG_FILE_PATH
az storage file upload --account-key $palo_alto_storage_account_key --account-name $palo_alto_storage_account_name --share-name $EGRESS_FILE_SHARE_NAME --source $EGRESS_FILE_PATH
az storage file upload --account-key $palo_alto_storage_account_key --account-name $palo_alto_storage_account_name --share-name $EGRESS_FILE_SHARE_NAME --source $INIT_CFG_FILE_PATH


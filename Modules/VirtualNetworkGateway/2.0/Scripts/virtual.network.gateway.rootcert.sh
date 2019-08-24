TENANT=$1
SP_USERNAME=$2
SP_PASSWORD=$3
KEY_VAULT_NAME=$4
KEY_VAULT_SECRET_NAME=$5

apt-get update
apt-get install -y strongswan strongswan-pki
mkdir -p ~/pki/{cacerts,certs,private}
chmod 700 ~/pki
ipsec pki --gen --outform pem > ~/pki/caKey.pem
ipsec pki --self --in ~/pki/caKey.pem --dn "CN=VPN CA" --ca --outform pem > ~/pki/caCert.pem
KEY=$(openssl x509 -in ~/pki/caCert.pem -outform der | base64 -w0)
# Store the base64 encoded public key of the rootCert as KeyVault secret
az login --service-principal --username $SP_USERNAME --password $SP_PASSWORD --tenant $TENANT
az keyvault secret set --vault-name $KEY_VAULT_NAME --name $KEY_VAULT_SECRET_NAME --value $KEY
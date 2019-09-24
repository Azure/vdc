KEY_VAULT_NAME=$1
KEY_VAULT_SECRET_NAME=$2
CWD=$3

apt-get update
apt-get install -y strongswan strongswan-pki
mkdir -p $CWD/pki/{cacerts,certs,private}
chmod 700 $CWD/pki
ipsec pki --gen --outform pem > $CWD/pki/caKey.pem
ipsec pki --self --in $CWD/pki/caKey.pem --dn "CN=VPN CA" --ca --outform pem > $CWD/pki/caCert.pem
KEY=$(openssl x509 -in $CWD/pki/caCert.pem -outform der | base64 -w0)
rm -r $CWD/pki
echo $KEY
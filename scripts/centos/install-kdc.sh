HOST_NAME=$1
DOMAIN=$2
hostnamectl set-hostname "$HOST_NAME.$DOMAIN"
yum install -y krb5-server krb5-libs krb5-auth-dialog krb5-workstation
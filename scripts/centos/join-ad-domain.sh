HOST_NAME=$1
DOMAIN=$2
DOMAIN_USERNAME=$3
DOMAIN_PASSWORD=$4
hostnamectl set-hostname "$HOST_NAME.$DOMAIN"
yum install -y realmd sssd krb5-workstation krb5-libs oddjob oddjob-mkhomedir samba-common-tools
service messagebus restart
service NetworkManager restart
service realmd restart
realm discover $DOMAIN
echo $DOMAIN_PASSWORD | kinit "$DOMAIN_USERNAME@$DOMAIN"
echo $DOMAIN_PASSWORD | realm join --verbose $DOMAIN -U "$DOMAIN_USERNAME@$DOMAIN"
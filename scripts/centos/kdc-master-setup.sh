DOMAIN=$1
NEW_DNS_ZONE=$2
KDC_MASTER_HOST_NAME=$3
KDC_SLAVE_HOST_NAME=$4
ADDS_VM1_HOST_NAME=$5
ADDS_VM2_HOST_NAME=$6
KERBEROS_DB_PASSWORD=$7
STORAGE_KEY=$8
STORAGE_ACCOUNT_URI=$9
bash -c "echo includedir /etc/krb5.conf.d/ > /etc/krb5.conf"
bash -c "echo -e \"[logging]\n default = FILE:/var/log/krb5libs.log\n kdc = FILE:/var/log/krb5kdc.log\n admin_server = FILE:/var/log/kadmind.log\" >> /etc/krb5.conf"
bash -c "echo -e \"[libdefaults]\n dns_lookup_realm = false\n ticket_lifetime = 24h\n renew_lifetime = 7d\n forwardable = true\n rdns = false\n default_realm = $NEW_DNS_ZONE\n default_ccache_name = KEYRING:persistent:%{uid}\n udp_preference_limit = 1\" >> /etc/krb5.conf"
bash -c "echo -e \"[realms]\n $NEW_DNS_ZONE = {\n   kdc = $KDC_MASTER_HOST_NAME.${NEW_DNS_ZONE,,}\n   kdc = $KDC_SLAVE_HOST_NAME.${NEW_DNS_ZONE,,}\n   admin_server = $KDC_MASTER_HOST_NAME.${NEW_DNS_ZONE,,}\n }\" >> /etc/krb5.conf"
bash -c "echo -e \" $DOMAIN = {\n   kdc = $ADDS_VM1_HOST_NAME.${DOMAIN,,}\n   kdc = $ADDS_VM2_HOST_NAME.${DOMAIN,,}\n   admin_server = $ADDS_VM1_HOST_NAME.${DOMAIN,,}\n   default_domain = $DOMAIN\n }\" >> /etc/krb5.conf"
kdb5_util create -s -P $KERBEROS_DB_PASSWORD
kadmin.local -q "addprinc -pw $KERBEROS_DB_PASSWORD admin/admin"
bash -c "echo \"*/admin@$NEW_DNS_ZONE *\" >> /var/kerberos/krb5kdc/kadm5.acl"
service krb5kdc start
service kadmin start
kadmin -p "admin/admin@$NEW_DNS_ZONE" -w $KERBEROS_DB_PASSWORD -q "addprinc -randkey \"host/$KDC_MASTER_HOST_NAME.${NEW_DNS_ZONE,,}\""
kadmin -p "admin/admin@$NEW_DNS_ZONE" -w $KERBEROS_DB_PASSWORD -q "addprinc -randkey \"host/$KDC_SLAVE_HOST_NAME.${NEW_DNS_ZONE,,}\""
kadmin -p "admin/admin@$NEW_DNS_ZONE" -w $KERBEROS_DB_PASSWORD -q "ktadd \"host/$KDC_MASTER_HOST_NAME.${NEW_DNS_ZONE,,}\""
kadmin -p "admin/admin@$NEW_DNS_ZONE" -w $KERBEROS_DB_PASSWORD -q "ktadd -k \"/tmp/$KDC_SLAVE_HOST_NAME.keytab\" \"host/$KDC_SLAVE_HOST_NAME.${NEW_DNS_ZONE,,}\""
bash -c "echo host/$KDC_MASTER_HOST_NAME.${NEW_DNS_ZONE,,}@$NEW_DNS_ZONE >> /var/kerberos/krb5kdc/kpropd.acl"
bash -c "echo host/$KDC_SLAVE_HOST_NAME.${NEW_DNS_ZONE,,}@$NEW_DNS_ZONE >> /var/kerberos/krb5kdc/kpropd.acl"
kadmin -p "admin/admin@$NEW_DNS_ZONE" -w $KERBEROS_DB_PASSWORD -q "addprinc -pw $KERBEROS_DB_PASSWORD -e aes256-cts-hmac-sha1-96 \"krbtgt/$NEW_DNS_ZONE@$DOMAIN\""
systemctl enable krb5kdc
systemctl enable kadmin


wget -O azcopy.tar.gz https://aka.ms/downloadazcopylinux64
tar -xf azcopy.tar.gz
sudo ./install.sh
yum install -y libunwind

azcopy --source "/tmp/$KDC_SLAVE_HOST_NAME.keytab" --destination "$STORAGE_ACCOUNT_URI/kdc/$KDC_SLAVE_HOST_NAME.keytab" --dest-key $STORAGE_KEY --quiet
azcopy --source /etc/krb5.conf --destination "$STORAGE_ACCOUNT_URI/kdc/etc/krb5.conf" --dest-key $STORAGE_KEY --quiet
azcopy --source /var/kerberos/krb5kdc --destination "$STORAGE_ACCOUNT_URI/kdc/var/kerberos/krb5kdc" --dest-key $STORAGE_KEY --recursive --quiet
rm -f /var/kerberos/krb5kdc/kpropd.acl 

KDC_SLAVE_HOST_NAME=$1
STORAGE_KEY=$2
STORAGE_ACCOUNT_URI=$3

wget -O azcopy.tar.gz https://aka.ms/downloadazcopylinux64
tar -xf azcopy.tar.gz
sudo ./install.sh
yum install -y libunwind

azcopy --source "$STORAGE_ACCOUNT_URI/kdc/$KDC_SLAVE_HOST_NAME.keytab" --destination /etc/krb5.keytab  --source-key $STORAGE_KEY --quiet

azcopy --source "$STORAGE_ACCOUNT_URI/kdc/etc/krb5.conf" --destination /etc/krb5.conf --source-key $STORAGE_KEY --quiet

azcopy --source "$STORAGE_ACCOUNT_URI/kdc/var/kerberos/krb5kdc" --destination /var/kerberos/krb5kdc --source-key $STORAGE_KEY --recursive --quiet

kpropd -S
systemctl enable krb5kdc
systemctl enable kprop

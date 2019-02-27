NEW_DNS_ZONE=$1
KDC_SLAVE_HOST_NAME=$2
kdb5_util dump kdcfile
kprop -r $NEW_DNS_ZONE -f kdcfile "$KDC_SLAVE_HOST_NAME.${NEW_DNS_ZONE,,}"
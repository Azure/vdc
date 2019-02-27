PROXY_URL=$1

#!/bin/bash

bash -c "echo HTTP_PROXY=$PROXY_URL >> /etc/profile"
bash -c "echo HTTPS_PROXY=$PROXY_URL >> /etc/profile"
bash -c "echo FTP_PROXY=$PROXY_URL >> /etc/profile"
bash -c "echo http_proxy=$PROXY_URL >> /etc/profile"
bash -c "echo https_proxy=$PROXY_URL >> /etc/profile"
bash -c "echo ftp_proxy=$PROXY_URL >> /etc/profile"

bash -c "echo export HTTP_PROXY HTTPS_PROXY FTP_PROXY http_proxy https_proxy ftp_proxy >> /etc/profile"

source /etc/profile


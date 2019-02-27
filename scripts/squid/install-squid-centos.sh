#!/bin/bash
bash -c "yum -y install epel-release && \ 
         yum -y install squid && systemctl start squid && systemctl enable squid"
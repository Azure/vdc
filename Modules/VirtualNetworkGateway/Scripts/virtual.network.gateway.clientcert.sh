CERT_DATA=$1
PASSWORD=$2
# Use a default value of "client" for USERNAME
USERNAME="client"
$CERT_DATA > ~/pki/caCert.pem
ipsec pki --gen --outform pem > ~/pki/"${USERNAME}Key.pem"    
ipsec pki --pub --in ~/pki/"${USERNAME}Key.pem" | ipsec pki --issue --cacert ~/pki/caCert.pem --cakey ~/pki/caKey.pem --dn "CN=${USERNAME}" --san "${USERNAME}" --flag clientAuth --outform pem > ~/pki/"${USERNAME}Cert.pem"
openssl pkcs12 -in ~/pki/"${USERNAME}Cert.pem" -inkey ~/pki/"${USERNAME}Key.pem" -certfile ~/pki/caCert.pem -export -out ~/pki/"${USERNAME}.p12" -password "pass:${PASSWORD}"
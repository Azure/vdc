apk add --update ca-certificates
apk add --update -t deps curl
az aks install-cli
for f in scripts/aks/*.sh
do
	chmod +x $f
done
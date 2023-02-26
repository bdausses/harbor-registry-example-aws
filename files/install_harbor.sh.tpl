#!/bin/bash

# Define variables:
RELEASES_URL=https://api.github.com/repos/goharbor/harbor/releases/latest
RELEASES_FILE=harbor_releases.json

# Determine if we have a fqdn or not then set that variable
IPorFQDN=${fqdn}

if [[ $IPorFQDN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  SET_SSL=FALSE
else
  SET_SSL=TRUE
fi

# Get releases file
wget --output-document=$RELEASES_FILE $RELEASES_URL

#Figure out latest version number and latest release URL
LATEST_VERSION=`cat $RELEASES_FILE|jq .name --raw-output`
LATEST_RELEASE_URL=`cat $RELEASES_FILE | jq ".assets[]|select(.name == \"harbor-online-installer-$LATEST_VERSION.tgz\").browser_download_url" --raw-output`

# Get latest release & unpack it
wget --output-document=harbor-online-installer-$LATEST_VERSION.tgz $LATEST_RELEASE_URL
tar -xzvf harbor-online-installer-$LATEST_VERSION.tgz

# Modify harbor.yml
cd harbor
cp harbor.yml.tmpl harbor.yml
sed -i "s/reg.mydomain.com/$IPorFQDN/g" harbor.yml

if [ "$SET_SSL" = "TRUE" ]
  then
    sudo certbot --register-unsafely-without-email --agree-tos -d ${fqdn}
    sudo systemctl stop nginx
    sudo systemctl disable nginx
    sed -i "s/certificate: \/your\/certificate\/path/certificate: \/etc\/letsencrypt\/live\/${fqdn}\/fullchain.pem/g" harbor.yml
    sed -i "s/private_key: \/your\/private\/key\/path/private_key: \/etc\/letsencrypt\/live\/${fqdn}\/privkey.pem/g" harbor.yml
  else
    sudo systemctl stop nginx
    sudo systemctl disable nginx
    sed -i "s/^https:$/# https:/g" harbor.yml
    sed -i "s/^  port: 443$/  # port: 443/g" harbor.yml
fi

# Execute install script
sudo ./install.sh --with-chartmuseum
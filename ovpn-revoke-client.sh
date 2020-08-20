#!/bin/bash

# Revoke a client

source ovpn.sh

read -p "Client: " client
echo "Revoking client $client"

docker run -v "$OVPN_DATA:/etc/openvpn" --rm -it kylemanna/openvpn ovpn_revokeclient "$client"

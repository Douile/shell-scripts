#!/bin/bash

# Create a new VPN client

source ovpn.sh

read -p "Client: " client
echo "Creating client $client"

mkdir -p ./clients

docker run -v "$OVPN_DATA:/etc/openvpn" --log-driver=none --rm -it kylemanna/openvpn easyrsa build-client-full "$client" nopass
docker run -v "$OVPN_DATA:/etc/openvpn" --rm -it kylemanna/openvpn ovpn_otp_user "$client"
docker run -v "$OVPN_DATA:/etc/openvpn" --log-driver=none --rm kylemanna/openvpn ovpn_getclient "$client" > "./clients/$client.ovpn"

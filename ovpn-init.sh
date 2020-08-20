#!/bin/bash

# Initialize openvpn

source ovpn.sh

read -p "Enter VPN domain: " OVPN_DOMAIN

docker volume create --name "$OVPN_DATA"
docker run -v "$OVPN_DATA:/etc/openvpn" --log-driver=none --rm kylemanna/openvpn ovpn_genconfig -u "udp://$OVPN_DOMAIN"
docker run -v "$OVPN_DATA:/etc/openvpn" --log-driver=none --rm -it kylemanna/openvpn ovpn_initpki

echo "All set up!"
echo "To run use:"
echo "docker run -v \"$OVPN_DATA:/etc/openvpn\" -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn"

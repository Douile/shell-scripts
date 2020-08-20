#!/bin/bash

# Open a bash shell

source ovpn.sh

docker run -v "$OVPN_DATA:/etc/openvpn" --rm -it kylemanna/openvpn bash

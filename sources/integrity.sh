#!/bin/bash

# Generate a HTML5 integrity hash
# example integrity http://localhost:5000/src/index.js
function integrity {
	printf "integrity=\"sha512-%s\"\n" $( wget -qO- $1 | openssl dgst -sha512 -binary | openssl base64 -A )
}
[[ $_ != $0 ]] && echo "Loaded integrity..." || integrity $1

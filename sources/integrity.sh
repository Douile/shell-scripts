#!/bin/bash

# Generate a HTML5 integrity hash
# example integrity http://localhost:5000/src/index.js
function integrity {
  hash="sha512"
  url="$1"
  case $1 in
    sha512|sha384|sha256)
      hash="$1"
      url="$2"
      ;;
  esac
	printf "integrity=\"$hash-%s\"\n" $( curl -s $url | openssl dgst -$hash -binary | openssl base64 -A )
}
[[ $_ = $0 ]] && integrity $@

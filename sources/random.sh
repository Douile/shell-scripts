#!/bin/sh

rnd() {
	base64 /dev/urandom | head -c $1
	echo ''
}

#!/bin/sh

gcp() {
	git commit -m "$1" && git push
}

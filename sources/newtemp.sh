#!/bin/bash

# Create a temp directory and cd into
newtemp() {
  lastclose=$(command -v closetemp)
  OLDPWD="$PWD"
  tmpdir=$(mktemp -d)
  cd "$tmpdir"
  alias closetemp="cd $OLDPWD && rm -rf $tmpdir; unalias closetemp; $lastclose"
  echo "Moved to temp directory $tmpdir use closetemp to delete and go back"
}

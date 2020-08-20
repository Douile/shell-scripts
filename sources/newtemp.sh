#!/bin/bash

# Create a temp directory and cd into
newtemp() {
  OLDPWD="$PWD"
  tmpdir=$(mktemp -d)
  cd "$tmpdir"
  alias closetemp="cd $OLDPWD && rm -r $tmpdir; unalias closetemp"
  echo "Moved to temp directory $tmpdir use closetemp to delete and go back"
}

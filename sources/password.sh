#!/bin/sh

generatePassword() {
  local cChars
  cChars=${1:-32}

  tr -dc ' -~' < /dev/urandom | head -c "$cChars"
}

checkPassword() {
  local pwd="$1"
  local hash
  hash=$(echo -n "$pwd" | sha1sum | cut -c -40)
  local expected=${hash#?????}
  local prefix=${hash%$expected}
  local match
  match=$(curl -s "https://api.pwnedpasswords.com/range/${prefix}" | grep -i "^$expected:" || return 1)
  echo "${match#*:}" | tr -d '\r'
}

generateAndCheckPassword() {
  pass="$(generatePassword $1)"
  echo "$pass"
  occ="$(checkPassword "$pass")"
  if [[ -z "$occ" ]]; then
    echo "No occurences"
  else
    echo "$occ occurences"
  fi
}

#!/bin/sh

set -eu

download_dir() {
  mkdir "$2"
  cd "$2"
  contents=$(curl -s "https://api.github.com/repos/xenlism/Grub-Themes/contents$1$2" | jq -r ".[] | @json")
  for content in $contents; do
    ftype=$(echo -n "$content" | jq -r ".type")
    if [ "$ftype" = "file" ]; then
      url=$(echo -n "$content" | jq -r ".download_url")
      echo "Downloading $(echo -n "$content" | jq -r ".name")"
      curl -sO "$url"
    elif [ "$ftype" = "dir" ]; then
      path=$(echo -n "$content" | jq -r ".name")
      download_dir "$1$2/" "$path"
    fi
  done
  cd ..
}

# Make sure dependencies are installed
paru -S --needed curl jq fzf

# Choose version
version=$(curl -s https://api.github.com/repos/xenlism/Grub-Themes/contents | jq -r ".[] | select(.type == \"dir\") | .name" | fzf)

tmpdir=$(mktemp -d)
echo "Installing in $tmpdir"
cd "$tmpdir"

download_dir "/" "$version"

cd "$version"

chmod +x ./install.sh

echo "Installing grub theme: $version"
sudo ./install.sh
rm -rf "$tmpdir"


#!/bin/sh

set -eux

tmpdir=$(mktemp -d)

cd "$tmpdir"

sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
rm -rf $tmpdir

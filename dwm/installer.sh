#!/bin/sh

set -eux

# Install/setup xorg
sudo pacman -S --needed git base-devel

# Download dwm
git clone https://git.suckless.org/dwm
cd dwm
read -p "DWM Latest version $(git describe --tags --abbrev=0) using 6.2 press enter to continue" a
git checkout 6.2

# Install patches
curl -O https://dwm.suckless.org/patches/actualfullscreen/dwm-actualfullscreen-20191112-cb3f58a.diff
# curl -O https://dwm.suckless.org/patches/gaps/dwm-gaps-6.0.diff
# curl -O https://dwm.suckless.org/patches/removeborder/dwm-removeborder-20200520-f09418b.diff
curl -O https://dwm.suckless.org/patches/floatrules/dwm-floatrules-6.2.diff
curl -O https://dwm.suckless.org/patches/systray/dwm-systray-6.2.diff
git apply -v -3 --ignore-space-change *.diff

cp config.def.h config.h
echo "Edit keybinds"
vim config.h

sudo make clean install
cat << EOF > dwm.desktop
[Desktop Entry]
Encoding=UTF-8
Name=Dwm
Comment=Dynamic window manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
sudo mv ./dwm.desktop /usr/share/xsessions/
cd ..

git clone https://git.suckless.org/dmenu
cd dmenu
read -p "Dmenu Latest version $(git describe --tags --abbrev=0) using 5.0 press enter to continue" a
git checkout 5.0
curl -O https://tools.suckless.org/dmenu/patches/case-insensitive/dmenu-caseinsensitive-5.0.diff
curl -O https://tools.suckless.org/dmenu/patches/grid/dmenu-grid-4.9.diff
curl -O https://tools.suckless.org/dmenu/patches/line-height/dmenu-lineheight-5.0.diff
curl -O https://tools.suckless.org/dmenu/patches/mouse-support/dmenu-mousesupport-5.0.diff
git apply -v -3 --ignore-space-change *.diff

cp config.def.h config.h
sudo make clean install

cd ..

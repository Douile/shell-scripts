#!/bin/sh

# Install qtile
paru -S --needed qtile

# Download config
git clone -b qtile --bare https://github.com/Douile/dotfiles.git ~/.dotfiles
git --work-tree="$HOME" --git-dir="$HOME/.dotfiles" checkout -f qtile

# Install dependencies
paru -S --needed python python-pip 
pip install Xlib psutil

paru -S --needed redshift nitrogen picom network-manager-applet firefox pcmanfm pavucontrol peek alacritty ttf-roboto rofi exa starship bash-completion maim dunst dmenu

# Configure lightdm
if [ -f /etc/lightdm/lightdm.conf ]; then
  sudo sed -i 's/#user-session=.*/\0\nuser-session=qtile/' /etc/lightdm/lightdm.conf
  sudo systemctl restart lightdm
fi

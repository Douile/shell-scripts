#!/bin/sh

# Setup xorg
paru -S --needed xorg xorg-drivers xorg-xinit
sudo X :0 -configure
sudo mv /root/xorg.conf.new /etc/X11/xorg.conf

# Install lightdm
paru -S --needed lightdm lightdm-slick-greeter

# Install themes
paru -S --needed gnome-themes-extra ttf-opensans gnome-backgrounds papirus-icon-theme

# Setup lightdm
sudo sed 's/#greeter-session=.*/\0\ngreeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
cat > /tmp/slick-greeter.conf << EOF
[Greeter]
draw-user-backgrounds=true
background=/usr/share/backgrounds/gnome/adwaita-morning.jpg
theme-name=Adwaita-dark
icon-theme-name=Papirus
font-name=Open Sans
show-clock=true
show-power=true
show-hostname=true
show-quit=true
EOF
sudo mv /tmp/slick-greeter.conf /etc/lightdm/slick-greeter.conf

# Enable lightdm
sudo systemctl enable --now lightdm

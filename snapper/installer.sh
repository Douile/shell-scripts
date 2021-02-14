#!/bin/sh

set -ex

echo "WARNING: Only run this installer on a system using btrfs"
echo "WARNING: This installer assumes that you already have an @snapshots subvolume that mounts to /.snapshots in FSTAB"
read -p "Press ctrl+c now to exit or enter to run the script" tmp

# Install snapper
paru -S --needed snapper

# Create root config
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots

# Install additional programs
paru -S --needed snap-pac grub-btrfs snap-pac-grub

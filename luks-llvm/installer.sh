#!/bin/sh

# Exit on error
set -e

# Functions
confirm() {
  read -p "$1" c
  if [ "$c" != "$2" ]; then
    return 1
  fi
}

loadkeys uk
echo "Checking internet"
ping -nc 1 archlinux.org
timedatectl set-ntp true

echo "Choose a disk to install to"
lsblk
read -p "> " DISK
if [ ! -b $DISK ]; then
  echo "Device doesn't exist"
  exit 1
fi

confirm "Use disk $DISK? (YES to continue) " "YES"

fdisk -l "$DISK"
echo "Create disk partitions"
fdisk "$DISK"
# g
# n
# 1
#
# +512M
# t
# 4
# n
# 2
#
#
# w

echo "Setup partitions and mount"
echo "cryptsetup luksFormat --type=luks1 ${DISK}2"
echo "cryptsetup open ${DISK}2 cryptlvm"
echo "pvcreate /dev/mapper/cryptlvm"
echo "vgcreate Volumes /dev/mapper/cryptlvm"
echo "lvcreate -L 8G Volumes -n swap"
echo "lvcreate -l 100%FREE Volumes -n root"
echo "mkfs.fat -F32 ${DISK}1"
echo "mkfs.btrfs /dev/Volumes/root"
echo "mkswap /dev/Volumes/swap"
echo "== OPTIONAL SUBVOLUMES for snapper =="
echo "mount /dev/Volumes/root /mnt"
echo "cd /mnt"
echo "btrfs subvolume create @"
echo "btrfs subvolume create @snapshots"
echo "btrfs subvolume create @home"
echo "btrfs subvolume create @logs"
echo "btrfs subvolume create @pc-cache"
echo "cd /"
echo "umount /mnt"
echo "mount -o compress=zstd,subvol=@ /dev/Volumes/root /mnt"
echo "mkdir -p /mnt/.snapshots"
echo "mount -o subvol=@snapshots /dev/Volumes/root/ /mnt/.snapshots"
echo "mkdir -p /mnt/home"
echo "mount -o subvol=@home /dev/Volumes/root /mnt/home"
echo "mkdir -p /mnt/var/log"
echo "mount -o subvol=@logs /dev/Volumes/root /mnt/var/log"
echo "mkdir -p /mnt/var/cache/pacman/pkg"
echo "mount -o subvol=@pc-cache /dev/Volumes/root /mnt/var/cache/pacman/pkg"
echo "mkdir -p /mnt/tmp"
echo "mount -t tmpfs tmpfs /mnt/tmp"
zsh
# ...
# cryptsetup open "{DISK}2" cryptlvm
# pvcreate /dev/mapper/cryptlvm
# vgcreate Volumes /dev/mapper/cryptlvm
# lvcreate -L 8G Volumes -n swap
# lvcreate -l 100%FREE Volumes -n root
# mkfs.fat -F32 "${DISK}1"
# mkfs.btrfs /dev/Volumes/root
# mkswap /dev/Volumes/swap
read -p "Enter root device: " ROOT
if [ ! -b $ROOT ]; then
  echo "Device doesn't exist"
  exit 1
fi
read -p "Enter swap directory: (blank for no swap) " SWAP
if [ ! -b $SWAP ] && [ "$swap" != "" ]; then
  echo "Device doesn't exist"
  exit 1
fi

read -p "Enter EFI device: " EFI
if [ ! -b $EFI ]; then
  echo "Device doesn't exist"
  exit 1
fi

read -p "Enter crypto disk device: " CRYPTODISK
if [ ! -b $CRYPTODISK ]; then
  echo "Device doesn't exist"
  exit 1
fi

echo "ROOT: $ROOT"
echo "SWAP: $SWAP"
echo "EFI: $EFI"
echo "CRYPTODISK: $CRYPTODISK"
confirm "Are disks OK? (YES to continue) "  "YES"

echo "Mounting..."
if mountpoint -q /mnt; then
  confirm "The root mountpoint (/mnt) is already mounted (YES to continue) " "YES"
else
  mount $ROOT /mnt
fi
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot
if [ "$SWAP" != "" ]; then
  swapon $SWAP
fi
echo "Installing packages..."
pacstrap /mnt base linux linux-firmware btrfs-progs base-devel
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
confirm "Is fstab ok? (YES to continue) " "YES"

cr() {
  arch-chroot /mnt $@
}

echo "Configuring time..."
cr ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
cr hwclock --systohc

echo "Generating locales..."
sed -i 's/\#\(en_GB.UTF-8 UTF-8\)/\1/' /mnt/etc/locale.gen
cr locale-gen
echo "LANG=en_GB.UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP=uk" > /mnt/etc/vconsole.conf

echo "Setting up hostname..."
read -p "Enter hostname: " HOSTNAME
echo "$HOSTNAME" > /mnt/etc/hostname
cat << EOF >> /mnt/etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME.localdomain  $HOSTNAME
EOF

echo "Installing packages..."
cr pacman -S --needed --noconfirm grub lvm2 efibootmgr vim htop man-db dash networkmanager pulseaudio pulseaudio-zeroconf

echo "Setting up initcpio..."
# BINARIES("/usr/bin/btrfs")
sed -i 's/^BINARIES=([^)]*)/BINARIES=("\/usr\/bin\/btrfs")/' /mnt/etc/mkinitcpio.conf
# HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)
sed -i 's/^HOOKS=([^)]*)/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)/' /mnt/etc/mkinitcpio.conf
#COMPRESSION="gzip"

less /mnt/etc/mkinitcpio.conf
read -p "Is mkinitcpio.conf ok? (YES to continue, EDIT to edit) " check
case $check in
"YES") ;;
"EDIT") vim /mnt/etc/mkinitcpio.conf ;;
*) exit 1
esac
cr mkinitcpio -P

echo "Setting up grub..."
# Get root UUID
PARTID=$(blkid -s PARTUUID -o value $ROOT)
# blkid of /dev/mapper/Volumes/root

if [ "$SWAP" != "" ]; then
  ESCAPE_SWAP=$(echo "$SWAP" | sed 's/\//\\\//g')
  sed -i "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)$\"/\1 resume=$ESCAPE_SWAP\"/" /mnt/etc/default/grub
fi

ESCAPE_CRYPT=$(echo "$CRYPTDISK" | sed 's/\//\\\//g')
sed -i "s/^\(GRUB_CMDLINE_LINUX=\"[^\"]*\)\"/\1 cryptdevice=PARTUUID=$PARTID:cryptlvm root=$ESCAPE_CRYPT\"/" /mnt/etc/default/grub
sed -i 's/^\(GRUB_PRELOAD_MODULES="[^"]*\)"/\1 lvm"/' /mnt/etc/default/grub
sed -i 's/^#\(GRUB_ENABLE_CRYPTODISK=i\).*/\1yes/' /mnt/etc/default/grub
less /mnt/etc/default/grub
read -p "Is grub default ok? (YES to continue, EDIT to edit) " check
case $check in
"YES") ;;
"EDIT") vim /mnt/etc/default/grub ;;
*) exit 1
esac

if confirm "Add custom grub options? (y for yes) " "y"; then
  cat << EOF >> /mnt/etc/grub.d/40_custom
menuentry "System shutdown" {
  echo "System shutting down..."
  halt
}
menuentry "System restart" {
  echo "System rebooting..."
  reboot
}
if [ ${grub_platform} == "efi" ]; then
  menuentry "Firmware setup" {
    fwsetup
  }
fi
EOF
fi

cr grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB $ROOT
cr grub-mkconfig -o /boot/grub/grub.cfg

echo "Set root password"
cr passwd
echo "Setting up programs..."
cr systemctl enable NetworkManager
rm /mnt/bin/sh
cr ln -s /bin/dash /bin/sh

echo "Make any manual changes then exit"
if cr bash; then
  echo "Setup done, thank you!"
else
  echo "WARNING: manual shell exited with error" 
fi
umount -R /mnt
echo "Done, you should reboot the system"

# Notes on setting up x
# pacman -S xorg xorg-drivers xorg-xinit
# Modify .xinitrc with WM at end
# To generate default config (as root)
# X :0 -configure
# mv /root/xorg.conf.new /etx/X11/xorg.conf

# Allow users to run startx
# sudo vim /etc/X11/Xwrapper.config
# allowed_users=anybody
# needs_root_rights=yes

# Add user services ($HOME/.config/systemd/user/)
# https://wiki.archlinux.org/index.php/Systemd/User#Xorg_as_a_systemd_user_service

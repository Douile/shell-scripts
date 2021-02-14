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
echo "For encrypted GRUB, LUKS + LVM create 3 partitions"
echo "1MB (boot patition)"
echo "500MB (fat32 efi partition)"
echo "Remainder (luks + lvm)"
fdisk "$DISK"

read -p "Enter main partition (where LLVM will be installed) (e.g. /dev/sda3): " ROOT
if [ ! -b $ROOT ]; then
  echo "Device doesn't exist"
  exit 1
fi

read -p "Enter swap size (e.g. 8G) (Leave blank for no swap): " SWAP_SIZE

read -p "Enter EFI partition (e.g. /dev/sda2): " EFI
if [ ! -b $EFI ]; then
  echo "Device doesn't exist"
  exit 1
fi

echo "Seting up partitions..."
cryptsetup luksFormat --type=luks1 "${ROOT}"
cryptsetup open ${ROOT} cryptlvm
pvcreate /dev/mapper/cryptlvm
vgcreate Volumes /dev/mapper/cryptlvm
if [ "$SWAP_SIZE" != "" ]; then
  lvcreate -L "$SWAP_SIZE" Volumes -n swap
fi
lvcreate -l 100%FREE Volumes -n root

echo "Formatting drives..."
mkfs.fat -F32 "$EFI"
mkfs.btrfs /dev/Volumes/root
if [ -b /dev/Volumes/swap ]; then
  mkswap /dev/Volumes/swap
fi
mountpoint=$(mktemp -d)
mount /dev/Volumes/root "$mountpoint"
cd "$mountpoint"
btrfs subvolume create @
btrfs subvolume create @snapshots
btrfs subvolume create @home
btrfs subvolume create @logs
btrfs subvolume create @pc-cache
cd /
umount "$mountpoint"
mount -o subvol=@ /dev/Volumes/root "$mountpoint"
mkdir -p "$mountpoint/.snapshots"
mount -o subvol=@snapshots /dev/Volumes/root "$mountpoint/.snapshots"
mkdir -p "$mountpoint/home"
mount -o subvol=@home /dev/Volumes/root "$mountpoint/home"
mkdir -p "$mountpoint/var/log"
mount -o subvol=@logs /dev/Volumes/root "$mountpoint/var/log"
mkdir -p "$mountpoint/var/cache/pacman/pkg"
mount -o subvol=@pc-cache /dev/Volumes/root "$mountpoint/var/cache/pacman/pkg"
mkdir -p "$mountpoint/efi"
mount "$EFI" "$mountpoint/efi"

echo "Installing packages..."
pacstrap "$mountpoint" --noconfirm base linux-zen linux-lts linux-firmware btrfs-progs base-devel
echo "Generating fstab..."
genfstab -U "$mountpoint" >> $mountpoint/etc/fstab
if [ -b /dev/Volumes/swap ]; then
  SWAPID=$(blkid -s UUID -o value /dev/mapper/Volumes-swap)
  echo -e "\n# /dev/mapper/Volumes-swap\nUUID=$SWAPID\tnone\tswap\tsw\t0\t0" >> $mountpoint/etc/fstab
fi
echo -e "\n# /tmp RAMDISK\nnone\t/tmp\ttmpfs\tdefaults\t0\t0" >> $mountpoint/etc/fstab
less "$mountpoint/etc/fstab"
confirm "Is fstab ok? (YES to continue) " "YES"

cr() {
  arch-chroot "$mountpoint" $@
}

echo "Creating keyfile"
mkdir -p "$mountpoint/root"
dd bs=512 count=4 if=/dev/random of="$mountpoint/root/cryptlvm.keyfile" iflag=fullblock
chmod 000 "$mountpoint/root/cryptlvm.keyfile"
cr cryptsetup -v luksAddKey "${ROOT}" /root/cryptlvm.keyfile

echo "Configuring time..."
cr ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
cr hwclock --systohc

echo "Generating locales..."
sed -i 's/\#\(en_GB.UTF-8 UTF-8\)/\1/' "$mountpoint/etc/locale.gen"
cr locale-gen
echo "LANG=en_GB.UTF-8" > $mountpoint/etc/locale.conf
echo "KEYMAP=uk" > $mountpoint/etc/vconsole.conf

echo "Setting up hostname..."
read -p "Enter hostname: " HOSTNAME
echo "$HOSTNAME" > $mountpoint/etc/hostname
cat << EOF >> $mountpoint/etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME.localdomain  $HOSTNAME
EOF

echo "Installing packages..."
cr pacman -S --needed --noconfirm grub lvm2 efibootmgr neovim htop man-db dash networkmanager pulseaudio pulseaudio-zeroconf

echo "Setting up initcpio..."

# BINARIES("/usr/bin/btrfs")
sed -i 's/^BINARIES=([^)]*)/BINARIES=("\/usr\/bin\/btrfs")/' "$mountpoint/etc/mkinitcpio.conf"
# HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)
sed -i 's/^HOOKS=([^)]*)/HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)/' "$mountpoint/etc/mkinitcpio.conf"
#COMPRESSION="gzip"
# FILES=("/root/cryptlvm.keyfile")
sed -i 's/^FILES=([^)]*)/FILES=("\/root\/cryptlvm.keyfile")/' "$mountpoint/etc/mkinitcpio.conf"

less $mountpoint/etc/mkinitcpio.conf
read -p "Is mkinitcpio.conf ok? (YES to continue, EDIT to edit) " check
case $check in
"YES") ;;
"EDIT") vim $mountpoint/etc/mkinitcpio.conf ;;
*) exit 1
esac
cr mkinitcpio -P
chmod 600 $mountpoint/boot/initramfs-linux*

echo "Setting up grub..."
# Get root UUID
PARTID=$(blkid -s PARTUUID -o value $ROOT)
# blkid of /dev/mapper/Volumes/root

if [ -b /dev/Volumes/swap ]; then
  sed -i "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)$\"/\1 resume=\/dev\/Volumes\/swap\"/" "$mountpoint/etc/default/grub"
fi

sed -i "s/^\(GRUB_CMDLINE_LINUX=\"[^\"]*\)\"/\1cryptdevice=PARTUUID=${PARTID}:cryptlvm root=\/dev\/Volumes\/root cryptkey=rootfs:\/root\/cryptlvm.keyfile\"/" "$mountpoint/etc/default/grub"
sed -i 's/^\(GRUB_PRELOAD_MODULES="[^"]*\)"/\1 lvm"/' "$mountpoint/etc/default/grub"
sed -i 's/^#\(GRUB_ENABLE_CRYPTODISK=\).*/\1y/' "$mountpoint/etc/default/grub"
less "$mountpoint/etc/default/grub"
read -p "Is grub default ok? (YES to continue, EDIT to edit) " check
case $check in
"YES") ;;
"EDIT") vim "$mountpoint/etc/default/grub" ;;
*) exit 1
esac

if confirm "Add custom grub options? (y for yes) " "y"; then
  cat << EOF >> $mountpoint/etc/grub.d/40_custom
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

cr grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB-arch $ROOT
cr grub-mkconfig -o /boot/grub/grub.cfg

echo "Set root password"
cr passwd
echo "Setting up programs..."
cr systemctl enable NetworkManager
rm $mountpoint/bin/sh
cr ln -s /bin/dash /bin/sh

echo "Make any manual changes then exit"
if cr bash; then
  echo "Setup done, thank you!"
else
  echo "WARNING: manual shell exited with error"
fi
umount -R "$mountpoint"
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

#!/bin/sh

set -e 

groupname="$1"
if [ "$groupname" = "" ]; then
  groupname="sudo"
fi

# Install doas
pacman -R sudo # Remove sudo
pacman -S --needed opendoas
# Create group if it doesn't exist
getent group | grep -z "$groupname:" || groupadd "$groupname"
# Add group to doas.conf
cat >> /etc/doas.conf << EOF
permit 0
permit :${groupname}
EOF

echo "Add a user to the \"$groupname\" group to allow them to get sudo access"
# Link doas to /bin/sudo
ln -s /bin/doas /bin/sudo

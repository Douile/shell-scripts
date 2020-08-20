#!/bin/bash

source ovpn-env.sh

changeOvpnVolumeName() {
  read -p "Enter ovpn volume name: " OVPN_DATA
  echo -e "#!/bin/bash\ndeclare -x OVPN_DATA=$OVPN_DATA" > ovpn-env.sh
}

if [ -z $OVPN_DATA ]; then
  changeOvpnVolumeName
else
  read -p "Ovpn volume \"$OVPN_DATA\", would you like to change? [y/N]: " confirm
  if [ "$confirm" = "y" ]; then
    changeOvpnVolumeName
  fi
fi

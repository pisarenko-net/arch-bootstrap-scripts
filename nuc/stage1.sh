#!/bin/bash

# run from bootstrapped machine: $ wget git.io/apfel_nuc_install -O - | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/nuc/stage1.sh" -F "code=apfel_nuc_install")

export USER="sergey"
export DOMAIN="pisarenko.net"
export FULL_NAME="Sergey Pisarenko"

eval "`/usr/bin/wget git.io/apfel_cli -O -`"
eval "`/usr/bin/wget git.io/apfel_xorg -O -`"

echo '==> Installing VirtualBox'
/usr/bin/pacman -S --noconfirm virtualbox
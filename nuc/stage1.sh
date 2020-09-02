#!/bin/bash

# run from bootstrapped machine: $ curl -L git.io/apfel_nuc_install | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/nuc/stage1.sh" -F "code=apfel_nuc_install")

export USER="sergey"
export DOMAIN="pisarenko.net"
export FULL_NAME="Sergey Pisarenko"

export AS="/usr/bin/sudo -u ${USER}"

if [ ! -f private.key ]; then
    echo "Download the GPG private key and save it to private.key first"
    exit 1
fi

echo "==> Importing GPG key for decrypting private configuration files"
cat private.key | $AS /usr/bin/gpg --import

eval "`/usr/bin/curl -L git.io/apfel_stage1`"

echo "==> Downloading configuration files and unlocking private configuration files"
$AS /usr/bin/git clone https://github.com/pisarenko-net/arch-bootstrap-scripts.git /tmp/scripts-repo
cd /tmp/scripts-repo
$AS /usr/bin/git secret reveal
$AS /usr/bin/cp -R /tmp/scripts-repo/common/configs /tmp/configs
$AS /usr/bin/cp -R /tmp/scripts-repo/nuc/configs/* /tmp/configs/
$AS /usr/bin/cp -R /tmp/scripts-repo/common/wallpapers /tmp/wallpapers
$AS /usr/bin/cp -R /tmp/scripts-repo/nuc/private /tmp/private
$AS /usr/bin/rm /tmp/private/*secret

eval "`/usr/bin/curl -L git.io/apfel_cli`"
eval "`/usr/bin/curl -L git.io/apfel_xorg`"

echo '==> Installing X driver and enhancements'
/usr/bin/pacman -S --noconfirm xf86-video-intel compton
$AS /usr/bin/xfconf-query -c xfwm4 -p /general/use_compositing -s false
$AS /usr/bin/cp -R /tmp/configs/compton.desktop /home/${USER}/.config/autostart/

echo '==> Installing and configuring bluetooth'
/usr/bin/pacman -S --noconfirm bluez bluez-utils
/usr/bin/sed -i 's/#AutoEnable=false/AutoEnable=true/' /etc/bluetooth/main.conf
cd /
/usr/bin/tar xvzf /tmp/private/bluetooth-pairings.tar.gz
/usr/bin/systemctl enable bluetooth

echo '==> Enabling better power management'
/usr/bin/pacman -S --noconfirm tlp
/usr/bin/systemctl enable tlp

echo '==> Installing VirtualBox, vagrant, packer and scripts'
/usr/bin/pacman -S --noconfirm virtualbox vagrant packer
cd /home/${USER}
$AS /usr/bin/git clone git@github.com:pisarenko-net/arch-bootstrap-scripts.git
$AS /usr/bin/git clone git@github.com:pisarenko-net/arch-packer-vagrant.git

echo '==> Installing VirtualBox extensions'
cd /home/${USER}
$AS /usr/bin/git clone https://aur.archlinux.org/virtualbox-ext-oracle.git
cd virtualbox-ext-oracle
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf virtualbox-ext-oracle

echo '==> Cleaning up'
$AS /usr/bin/gpg --batch --delete-secret-keys B01ACF22C49D7DE67F625C6F538D8B004CA3C11A
/usr/bin/rm -rf /tmp/scripts-repo
/usr/bin/rm -rf /tmp/configs
/usr/bin/rm -rf /tmp/private
/usr/bin/rm -rf /tmp/wallpapers

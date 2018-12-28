#!/bin/bash

# run from bootstrapped machine: $ wget git.io/apfel_xorg -O - | sh
# (created with: $ curl -i https://git.io -F "url=" -F "code=apfel_xorg")

AS="/usr/bin/sudo -u ${USER}"

# install desktop environment
echo '==> Installing desktop environment'
/usr/bin/pacman -S --noconfirm xorg-server xorg-xinit lxdm xfce4

# configure desktop manager
echo '==> Enabling desktop manager'
/usr/bin/sed -i "s/# autologin=dgod/autologin=${USER}/" /etc/lxdm/lxdm.conf
/usr/bin/sed -i 's/# session=\/usr\/bin\/startlxde/session=\/usr\/bin\/startxfce4/' /etc/lxdm/lxdm.conf
/usr/bin/systemctl enable lxdm.service

# install fonts
echo '==> Installing fonts'
/usr/bin/pacman -S --noconfirm noto-fonts ttf-roboto ttf-dejavu adobe-source-code-pro-fonts ttf-ubuntu-font-family

# install tools
echo '==> Installing useful tools'
/usr/bin/pacman -S --noconfirm terminator meld parcellite thunar-archive-plugin gvfs tk pinta
#$AS /bin/dconf load /org/gnome/meld/ < /tmp/configs/meld

# install albert
echo '==> Installing albert (AUR)'
cd /home/${USER}
$AS /usr/bin/git clone https://aur.archlinux.org/albert-lite.git
cd albert-lite
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf albert-lite

# install sublime
echo '==> Installing sublime (AUR)'
$AS /usr/bin/git clone https://aur.archlinux.org/sublime-text-dev.git
cd sublime-text-dev
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf sublime-text-dev
/usr/bin/echo 'alias subl="/bin/subl3"' >> /home/${USER}/.zshrc
/usr/bin/echo 'alias mc="EDITOR=/bin/subl3 /bin/mc"' >> /home/${USER}/.zshrc
#$AS /usr/bin/cp -r /tmp/configs/sublime-text-3 .config/

# install Google Chrome
echo '==> Installing Google Chrome (AUR)'
cd /home/${USER}
$AS /usr/bin/git clone https://aur.archlinux.org/google-chrome.git
cd google-chrome
$AS /usr/bin/makepkg -si --noconfirm
cd ..
$AS /usr/bin/rm -rf google-chrome

# customize XFCE
# TODO

# install Sublime license, when available
# TODO

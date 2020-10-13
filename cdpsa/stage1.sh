#!/bin/bash

# run from bootstrapped machine: $ curl -L git.io/apfel_cdpsa_install | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/cdpsa/stage1.sh" -F "code=apfel_cdpsa_install")

export USER="sergey"

export AS="/usr/bin/sudo -u ${USER}"

if [ ! -f private.key ]; then
    echo "Download the GPG private key and save it to private.key first"
    exit 1
fi

echo "==> Importing GPG key for decrypting private configuration files"
cat private.key | $AS /usr/bin/gpg --import

echo "==> Refresh and upgrade packages"
/usr/bin/apt update
/usr/bin/apt -y upgrade

echo "==> Installing tools"
/usr/bin/apt -y install git tcpdump netcat tmux hwinfo mc zip lsof dnsutils git-secret autofs neovim smbclient 

echo "==> Installing audio tools"
/usr/bin/apt -y install eject ffmpeg

echo "==> Downloading configuration files and unlocking private configuration files"
$AS /usr/bin/git clone https://github.com/pisarenko-net/arch-bootstrap-scripts.git /tmp/scripts-repo
cd /tmp/scripts-repo
$AS /usr/bin/git secret reveal
$AS /bin/cp -R /tmp/scripts-repo/common/configs /tmp/configs
$AS /bin/cp -R /tmp/scripts-repo/cdpsa/configs/* /tmp/configs/
$AS /bin/cp -R /tmp/scripts-repo/cdpsa/private /tmp/private
$AS /bin/rm /tmp/private/*secret

echo "==> Configuring Wi-Fi"
/bin/cp /tmp/private/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf

echo "==> Enabling SMB mount"
echo "/mnt /etc/auto.music --timeout 0 --browse" >> /etc/auto.master
/bin/cp /tmp/private/auto.music /etc/
/bin/chmod 640 /etc/auto.music

echo "==> Installing Minidisc library"
$AS /usr/bin/git clone https://github.com/pisarenko-net/md-uploader.git /home/${USER}/minidisc

echo "==> Installing CDP-SA software"
$AS /usr/bin/git clone https://github.com/pisarenko-net/cdp-sa.git /home/${USER}/cdp-sa

echo '==> Cleaning up'
$AS /usr/bin/gpg --batch --delete-secret-keys B01ACF22C49D7DE67F625C6F538D8B004CA3C11A
/bin/rm -rf /tmp/scripts-repo
/bin/rm -rf /tmp/configs
/bin/rm -rf /tmp/private

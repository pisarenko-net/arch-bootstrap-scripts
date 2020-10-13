#!/bin/bash

# run from bootstrapped machine: $ curl -L git.io/apfel_cdpsa_install | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/cdpsa/stage1.sh" -F "code=apfel_cdpsa_install")

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

echo '==> Cleaning up'
$AS /usr/bin/gpg --batch --delete-secret-keys B01ACF22C49D7DE67F625C6F538D8B004CA3C11A
/usr/bin/rm -rf /tmp/scripts-repo
/usr/bin/rm -rf /tmp/configs
/usr/bin/rm -rf /tmp/private
/usr/bin/rm -rf /tmp/wallpapers

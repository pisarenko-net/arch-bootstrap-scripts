#!/bin/bash

# run from bootstrapped machine: $ wget git.io/apfel_router_install -O - | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/router/stage1.sh" -F "code=apfel_router_install")

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

echo "==> Downloading configuration files and unlocking private configuration files"
$AS /usr/bin/git clone https://github.com/pisarenko-net/arch-bootstrap-scripts.git /tmp/scripts-repo
cd /tmp/scripts-repo
$AS /usr/bin/git secret reveal
$AS /usr/bin/cp -R /tmp/scripts-repo/common/configs /tmp/configs
$AS /usr/bin/cp -R /tmp/scripts-repo/router/configs/* /tmp/configs/
$AS /usr/bin/cp -R /tmp/scripts-repo/router/private /tmp/private
$AS /usr/bin/rm /tmp/private/*secret

eval "`/usr/bin/wget git.io/apfel_cli -O -`"

echo '==> Enabling better power management'
/usr/bin/pacman -S --noconfirm tlp
/usr/bin/systemctl enable tlp

echo '==> Setting OpenSSH to listen only on the trusted network'
/usr/bin/sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 192.168.10.1/' /etc/ssh/sshd_config

echo '==> Setup dnsmasq (DHCP + DNS)'
/usr/bin/pacman -S --noconfirm dnsmasq
/usr/bin/cp /tmp/private/dnsmasq.conf /etc/
/usr/bin/cp /tmp/private/hosts /etc/
/usr/bin/systemctl enable dnsmasq
/usr/bin/systemctl start dnsmasq
/usr/bin/sed -i "s/DNS=.*/DNS=\('127.0.0.1'\)/" /etc/netctl/wan

echo '==> Setting up iptables'
/usr/bin/cp /tmp/private/sysctl_ip_forward /etc/sysctl.d/30-ip_forward.conf
/usr/bin/sysctl net.ipv4.ip_forward=1
/usr/bin/pacman -S --noconfirm iptables
/usr/bin/systemctl enable iptables
/usr/bin/systemctl start iptables
/usr/bin/iptables-restore < /tmp/private/iptables-rules
/usr/bin/iptables-save > /etc/iptables/iptables.rules

echo '==> Cleaning up'
/usr/bin/rm -rf /tmp/scripts-repo
/usr/bin/rm -rf /tmp/configs
/usr/bin/rm -rf /tmp/private

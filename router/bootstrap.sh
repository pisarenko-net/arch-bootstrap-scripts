#!/bin/bash

# run and execute after dropping into arch installer: $ wget git.io/apfel_router -O - | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/router/bootstrap.sh" -F "code=apfel_router")

export DISK='/dev/sda'

export FQDN='router.bethania'
export WAN_IFACE="eth0"
export LAN_IFACE="eth1"
export USER='sergey'
export PASSWORD=$(/usr/bin/openssl passwd -crypt 'test')
export ROOT_PASSWORD=`/usr/bin/openssl rand -base64 32`
export KEYMAP='us'
export LANGUAGE='en_US.UTF-8'
export TIMEZONE='Europe/Zurich'

export CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
export EFI_PARTITION="${DISK}1"
export BOOT_PARTITION="${DISK}2"
export ROOT_PARTITION="${DISK}3"
export ROOT_PASSPHRASE=`/usr/bin/openssl rand -base64 32`
export TARGET_DIR='/mnt'
export ENC_KEY_PATH="${TARGET_DIR}/enc.key"
export COUNTRY='CH'
export MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

eval "`/usr/bin/wget git.io/apfel_bootstrap -O -`"

echo '==> Configuring networks'
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/wan"
Interface=${WAN_IFACE}
Connection=ethernet
IP=dhcp
DNS=('127.0.0.1' '8.8.8.8' '8.8.4.4')
EOF
/usr/bin/cat <<-EOF > "${TARGET_DIR}/etc/netctl/trusted_lan"
Interface=${LAN_IFACE}
Connection=ethernet
IP=static
Address=('192.168.10.1/24')
EOF
/usr/bin/arch-chroot ${TARGET_DIR} /usr/bin/netctl enable wan
/usr/bin/arch-chroot ${TARGET_DIR} /usr/bin/netctl enable trusted_lan

echo '==> Install complete!'
/usr/bin/sleep 5
/usr/bin/umount ${TARGET_DIR}
/usr/bin/reboot

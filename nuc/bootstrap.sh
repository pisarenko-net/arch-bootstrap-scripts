#!/bin/bash

# run and execute after dropping into arch installer: $ wget git.io/apfel_nuc -O - | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/nuc/bootstrap.sh" -F "code=apfel_nuc")
export DISK='/dev/nvme0n1'

export FQDN='arch.bethania'
export IP='192.168.69.20/24'
export GW='192.168.69.1'
export IFACE="eth0"
export USER='sergey'
export PASSWORD=$(/usr/bin/openssl passwd -crypt 'test')
export ROOT_PASSWORD=`/usr/bin/openssl rand -base64 32`
export KEYMAP='us'
export LANGUAGE='en_US.UTF-8'
export TIMEZONE='Europe/Zurich'

export CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
export EFI_PARTITION="${DISK}p1"
export BOOT_PARTITION="${DISK}p2"
export ROOT_PARTITION="${DISK}p3"
export ROOT_PASSPHRASE=`/usr/bin/openssl rand -base64 32`
export TARGET_DIR='/mnt'
export ENC_KEY_PATH="${TARGET_DIR}/enc.key"
export COUNTRY='CH'
export MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

eval "/usr/bin/wget git.io/apfel_bootstrap -O -"
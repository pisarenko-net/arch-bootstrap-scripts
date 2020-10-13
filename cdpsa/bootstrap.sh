#!/bin/bash

# run and execute after dropping into arch installer: $ curl -L git.io/apfel_cdpsa | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/cdpsa/bootstrap.sh" -F "code=apfel_cdpsa")

export DISK='/dev/sda'
export ROOT_PARTITION='/dev/sda2'
export USER='sergey'
export PASSWORD=$(/usr/bin/openssl passwd -crypt 'test')
export ROOT_PASSWORD=`/usr/bin/openssl rand -base64 32`
export KEYMAP='us'
export TIMEZONE='Europe/Zurich'
export COUNTRY='CH'
export FQDN='cdpsa.bethania'
export TARGET_DIR='/mnt'
export CONFIG_SCRIPT='/usr/local/bin/raspberry_install.sh'
export GROUPS="adm,dialout,cdrom,sudo,audio,video,plugdev,games,input,netdev,gpio,i2c,spi,users"

echo '==> Downloading OS'
/usr/bin/curl -L https://downloads.raspberrypi.org/raspios_lite_armhf_latest | gunzip > /tmp/raspberry_os.img

echo '==> Installing image to disk'
/bin/dd bs=4M if=/tmp/raspberry_os.img of=${DISK} status=progress conv=fsync

echo "==> Mounting root to ${TARGET_DIR}"
/bin/mount ${ROOT_PARTITION} ${TARGET_DIR}

echo '==> Generating the system configuration script'
/usr/bin/install --mode=0755 /dev/null "${TARGET_DIR}${CONFIG_SCRIPT}"

/bin/cat <<-EOF > "${TARGET_DIR}${CONFIG_SCRIPT}"
# Reset root password
echo "root:${ROOT_PASSWORD}" | /usr/sbin/chpasswd
# Set hostname
echo '${FQDN}' > /etc/hostname
# Set timezone
/usr/bin/timedatectl set-timezone "${TIMEZONE}"
# Set keyboard layout
/bin/sed -i 's/XKBLAYOUT="gb"/XKBLAYOUT="us"/' /etc/default/keyboard
/usr/sbin/dpkg-reconfigure --frontend=noninteractive keyboard-configuration
# Create user
/usr/sbin/useradd --password ${PASSWORD} --create-home --user-group ${USER} -G ${GROUPS}
echo '${USER} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_${USER}
/bin/chmod 0440 /etc/sudoers.d/10_${USER}
/usr/bin/install --directory --owner=${USER} --group=${USER} --mode=0700 /home/${USER}/.ssh
/usr/bin/curl --output /home/${USER}/.ssh/authorized_keys --location https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/master-key.pub
/bin/chown ${USER}:${USER} /home/${USER}/.ssh/authorized_keys
/bin/chmod 0600 /home/${USER}/.ssh/authorized_keys
# Delete standard user
/usr/sbin/userdel -r -f pi
# Enable SSH
/bin/sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
/bin/systemctl enable ssh
EOF

echo '==> Entering chroot and configuring system'
/usr/sbin/chroot ${TARGET_DIR} ${CONFIG_SCRIPT}
/bin/rm "${TARGET_DIR}${CONFIG_SCRIPT}"
/bin/rm /tmp/raspberry_os.img

echo '==> Install complete!'
/bin/sleep 5
/bin/umount ${TARGET_DIR}
/sbin/reboot

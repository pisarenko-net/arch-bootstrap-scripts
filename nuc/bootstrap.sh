#!/bin/bash

# run and execute after dropping into arch installer: $ wget git.io/apfel_nuc -O - | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/nuc/bootstrap.sh" -F "code=apfel_nuc")
DISK='/dev/nvme0n1'

FQDN='arch.bethania'
IPADDR='192.168.69.20'
GW='192.168.69.1'
IFACE="eth0"
USER='sergey'
PASSWORD=$(/usr/bin/openssl passwd -crypt 'test')
KEYMAP='us'
LANGUAGE='en_US.UTF-8'
TIMEZONE='Europe/Zurich'

CONFIG_SCRIPT='/usr/local/bin/arch-config.sh'
EFI_PARTITION="${DISK}p1"
BOOT_PARTITION="${DISK}p2"
ROOT_PARTITION="${DISK}p3"
ROOT_PASSPHRASE=`/usr/bin/openssl rand -base64 128`
TARGET_DIR='/mnt'
COUNTRY='CH'
MIRRORLIST="https://www.archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

echo "==> Create GPT partition table on ${DISK}"
/usr/bin/sgdisk -og ${DISK}

echo "==> Destroying magic strings and signatures on ${DISK}"
/usr/bin/dd if=/dev/zero of=${DISK} bs=512 count=2048
/usr/bin/wipefs --all ${DISK}

echo "==> Creating EFI System partition on ${DISK}"
/usr/bin/sgdisk -n 1:2048:1050623 -c 1:"EFI System partition" -t 1:ef00 ${DISK}

echo "==> Creating boot partition on ${DISK}"
/usr/bin/sgdisk -n 2:1050624:1460223 -c 2:"Boot partition" -t 2:8300 ${DISK}

echo "==> Creating /root partition on ${DISK}"
ENDSECTOR=`/usr/bin/sgdisk -E ${DISK}`
/usr/bin/sgdisk -n 3:1460224:$ENDSECTOR -c 3:"Root partition" -t 3:8E00 ${DISK}

echo '==> Creating EFI filesystem (FAT32)'
/usr/bin/mkfs.fat -F32 $EFI_PARTITION

echo '==> Creating /boot filesystem (ext2)'
/usr/bin/mkfs.ext2 -F ${BOOT_PARTITION}

echo '==> Creating encrypted /root filesystem (btrfs)'
echo $ROOT_PASSHPRASE | /usr/bin/cryptsetup luksFormat $ROOT_PARTITION -d -
echo $ROOT_PASSHPRASE | /usr/bin/cryptsetup open $ROOT_PARTITION cryptlvm -d -
/usr/bin/pvcreate /dev/mapper/cryptlvm
/usr/bin/vgcreate vg0 /dev/mapper/cryptlvm
/usr/bin/lvcreate -l 100%FREE vg0 -n root
/usr/bin/mkfs.btrfs /dev/mapper/vg0-root

echo "==> Mounting /root to ${TARGET_DIR}"
/usr/bin/mount /dev/mapper/vg0-root ${TARGET_DIR}
echo "==> Mounting /boot to ${TARGET_DIR}/boot"
/usr/bin/mkdir ${TARGET_DIR}/boot
/usr/bin/mount ${BOOT_PARTITION} ${TARGET_DIR}/boot
echo "==> Mounting EFI partition"
/usr/bin/mkdir ${TARGET_DIR}/boot/efi
/usr/bin/mount $EFI_PARTITION ${TARGET_DIR}/boot/efi

echo "==> Setting local mirror"
/usr/bin/curl -s "$MIRRORLIST" |  sed 's/^#Server/Server/' > /etc/pacman.d/mirrorlist

echo '==> Bootstrapping the base installation'
/usr/bin/pacstrap ${TARGET_DIR} base base-devel btrfs-progs neovim openssh grub-efi-x86_64 efibootmgr net-tools intel-ucode

echo '==> Generating the filesystem table'
/usr/bin/genfstab -U ${TARGET_DIR} >> "${TARGET_DIR}/etc/fstab"

echo '==> Altering default GRUB configuration'
/usr/bin/sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "${TARGET_DIR}/etc/default/grub"
/usr/bin/sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet cryptdevice=UUID=$(blkid ${ROOT_PARTITION} -s UUID -o value):cryptlvm\"/" "${TARGET_DIR}/etc/default/grub"

echo '==> Generating the system configuration script'
/usr/bin/install --mode=0755 /dev/null "${TARGET_DIR}${CONFIG_SCRIPT}"

echo '==> LVM work-around'
/usr/bin/mkdir ${TARGET_DIR}/hostlvm
/usr/bin/mount --bind /run/lvm ${TARGET_DIR}/hostlvm

echo '==> Generating network configuration'
cat <<-EOF > "${TARGET_DIR}/etc/netctl/static_config"
Interface=${IFACE}
Connection=ethernet
IP=static
Address='${IP_ADDRESS}'
Gateway='${GW}'
DNS='${GW}'
EOF

echo '==> Generating system configuration script'
cat <<-EOF > "${TARGET_DIR}${CONFIG_SCRIPT}"
/usr/bin/ln -s /hostlvm /run/lvm
/usr/bin/sed -i 's/HOOKS=.*/HOOKS=(base udev autodetect modconf block keymap encrypt lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
# GRUB bootloader installation
/usr/bin/grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
# keyless boot
/usr/bin/dd bs=512 count=8 if=/dev/urandom of=/crypto_keyfile.bin
/usr/bin/chmod 000 /crypto_keyfile.bin
echo "$ROOT_PASSPHRASE" | /usr/bin/cryptsetup luksAddKey ${ROOT_PARTITION} /crypto_keyfile.bin -d -
/usr/bin/sed -i 's\^FILES=.*\FILES="/crypto_keyfile.bin"\g' /etc/mkinitcpio.conf
#
/usr/bin/mkinitcpio -p linux
/usr/bin/chmod 600 /boot/initramfs-linux*
#
/usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
#
echo '${FQDN}' > /etc/hostname
/usr/bin/ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
/usr/bin/sed -i 's/#${LANGUAGE}/${LANGUAGE}/' /etc/locale.gen
/usr/bin/locale-gen
/usr/bin/usermod --password ${PASSWORD} root
# https://wiki.archlinux.org/index.php/Network_Configuration#Device_names
/usr/bin/netctl enable static_config
/usr/bin/systemctl enable sshd.service
/usr/bin/useradd --password ${PASSWORD} --create-home --user-group sergey
echo 'sergey ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_sergey
/usr/bin/chmod 0440 /etc/sudoers.d/10_sergey
/usr/bin/install --directory --owner=sergey --group=sergey --mode=0700 /home/sergey/.ssh
/usr/bin/curl --output /home/sergey/.ssh/authorized_keys --location https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/master-key.pub
/usr/bin/chown sergey:sergey /home/sergey/.ssh/authorized_keys
/usr/bin/chmod 0600 /home/sergey/.ssh/authorized_keys
# Clean the pacman cache.
/usr/bin/yes | /usr/bin/pacman -Scc
EOF

echo '==> Entering chroot and configuring system'
/usr/bin/arch-chroot ${TARGET_DIR} ${CONFIG_SCRIPT}
rm "${TARGET_DIR}${CONFIG_SCRIPT}"

/usr/bin/umount ${TARGET_DIR}/hostlvm
/usr/bin/rm -rf ${TARGET_DIR}/hostlvm

echo '==> Install complete!'
/usr/bin/sleep 5
/usr/bin/umount ${TARGET_DIR}/boot/efi
/usr/bin/umount ${TARGET_DIR}/boot
/usr/bin/umount ${TARGET_DIR}
/usr/bin/reboot
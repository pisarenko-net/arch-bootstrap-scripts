#!/bin/bash

# Install a base bootable Arch system accessible over SSH. Networking setup is left for the specific device setup scripts.

# run and execute from specific configuration scripts: $ wget git.io/apfel_bootstrap -O - | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/common/bootstrap.sh" -F "code=apfel_bootstrap")

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
echo ${ROOT_PASSPHRASE} > enc.key
/usr/bin/cryptsetup -q luksFormat $ROOT_PARTITION --key-file=enc.key
/usr/bin/cryptsetup open $ROOT_PARTITION cryptlvm --key-file=enc.key
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
/usr/bin/pacstrap ${TARGET_DIR} base base-devel lvm2 linux linux-firmware btrfs-progs netctl neovim dhcpcd openssh grub-efi-x86_64 efibootmgr net-tools intel-ucode wget git

echo '==> Generating the filesystem table'
/usr/bin/genfstab -U ${TARGET_DIR} >> "${TARGET_DIR}/etc/fstab"

echo '==> Altering default GRUB configuration'
/usr/bin/sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "${TARGET_DIR}/etc/default/grub"
/usr/bin/sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet rd.udev.log-priority=3 cryptdevice=UUID=$(blkid ${ROOT_PARTITION} -s UUID -o value):cryptlvm\"/" "${TARGET_DIR}/etc/default/grub"

echo '==> Generating the system configuration script'
/usr/bin/install --mode=0755 /dev/null "${TARGET_DIR}${CONFIG_SCRIPT}"

echo '==> LVM work-around'
/usr/bin/mkdir ${TARGET_DIR}/hostlvm
/usr/bin/mount --bind /run/lvm ${TARGET_DIR}/hostlvm

echo '==> Generating system configuration script'
echo ${ROOT_PASSPHRASE} > ${ENC_KEY_PATH}
/usr/bin/cat <<-EOF > "${TARGET_DIR}${CONFIG_SCRIPT}"
/usr/bin/ln -s /hostlvm /run/lvm
/usr/bin/sed -i 's/HOOKS=.*/HOOKS=(base udev autodetect modconf block keymap encrypt lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
# keyless boot
/usr/bin/dd bs=512 count=8 if=/dev/urandom of=/crypto_keyfile.bin
/usr/bin/chmod 000 /crypto_keyfile.bin
/usr/bin/cryptsetup luksAddKey ${ROOT_PARTITION} /crypto_keyfile.bin --key-file=/enc.key
/usr/bin/sed -i 's\^FILES=.*\FILES="/crypto_keyfile.bin"\g' /etc/mkinitcpio.conf
#
/usr/bin/mkinitcpio -p linux
/usr/bin/chmod 600 /boot/initramfs-linux*
#
# GRUB bootloader installation
/usr/bin/grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
/usr/bin/grub-mkconfig -o /boot/grub/grub.cfg
/usr/bin/sed -i '/echo/d' /boot/grub/grub.cfg
#
echo '${FQDN}' > /etc/hostname
/usr/bin/ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo 'KEYMAP=${KEYMAP}' > /etc/vconsole.conf
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
/usr/bin/sed -i 's/#${LANGUAGE}/${LANGUAGE}/' /etc/locale.gen
/usr/bin/locale-gen
echo "root:${ROOT_PASSWORD}" | /usr/bin/chpasswd
# https://wiki.archlinux.org/index.php/Network_Configuration#Device_names
/usr/bin/ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules
/usr/bin/systemctl enable sshd.service
/usr/bin/useradd --password ${PASSWORD} --create-home --user-group ${USER}
echo '${USER} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers.d/10_${USER}
/usr/bin/chmod 0440 /etc/sudoers.d/10_${USER}
/usr/bin/install --directory --owner=${USER} --group=${USER} --mode=0700 /home/${USER}/.ssh
/usr/bin/curl --output /home/${USER}/.ssh/authorized_keys --location https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/master-key.pub
/usr/bin/chown ${USER}:${USER} /home/${USER}/.ssh/authorized_keys
/usr/bin/chmod 0600 /home/${USER}/.ssh/authorized_keys
/usr/bin/sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
/usr/bin/ln -s /usr/bin/nvim /usr/bin/vi
/usr/bin/ln -s /usr/bin/nvim /usr/bin/vim
#
/usr/bin/hwclock --systohc --utc
# Clean the pacman cache.
/usr/bin/yes | /usr/bin/pacman -Scc
EOF

echo '==> Entering chroot and configuring system'
/usr/bin/arch-chroot ${TARGET_DIR} ${CONFIG_SCRIPT}
/usr/bin/rm "${TARGET_DIR}${CONFIG_SCRIPT}"
/usr/bin/rm "${ENC_KEY_PATH}"

/usr/bin/umount ${TARGET_DIR}/hostlvm
/usr/bin/rm -rf ${TARGET_DIR}/hostlvm

/usr/bin/umount ${TARGET_DIR}/boot/efi
/usr/bin/umount ${TARGET_DIR}/boot

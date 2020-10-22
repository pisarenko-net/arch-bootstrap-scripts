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

echo "==> Disabling built-in audio"
echo "blacklist snd_bcm2835" > /etc/modprobe.d/blacklist-audio.conf

echo "==> Installing pulseaudio"
/usr/bin/apt -y install pulseaudio pulsemixer pulseaudio-utils
/bin/cat <<-EOF > /etc/systemd/system/pulseaudio.service
[Unit]
Description=PulseAudio system server

[Service]
Type=simple
ExecStart=pulseaudio --daemonize=no --system --realtime --log-target=journal

[Install]
WantedBy=multi-user.target
EOF
/bin/sed -i 's/load-module module-native-protocol-unix/load-module module-native-protocol-unix auth-anonymous=1/g' /etc/pulse/system.pa
echo "load-module module-combine-sink sink_name=combined" >> /etc/pulse/system.pa
echo "set-default-sink combined" >> /etc/pulse/system.pa
/bin/systemctl --system enable pulseaudio.service
/bin/systemctl start pulseaudio.service

echo "==> Configuring Wi-Fi"
/bin/cp /tmp/private/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf

echo "==> Enabling IR sensor"
/bin/su -c "grep '^deb ' /etc/apt/sources.list | sed 's/^deb/deb-src/g' > /etc/apt/sources.list.d/deb-src.list"
/usr/bin/apt update
/usr/bin/apt -y build-dep lirc
/usr/bin/apt -y install devscripts
$AS /bin/mkdir /home/${USER}/lirc-build
cd /home/${USER}/lirc-build
$AS /usr/bin/apt source lirc
$AS /bin/cp /tmp/configs/lirc-gpio-ir-0.10.patch /home/${USER}/lirc-build
$AS /usr/bin/patch -p0 -i lirc-gpio-ir-0.10.patch
cd /home/${USER}/lirc-build/lirc-0.10.1
$AS /usr/bin/debuild -uc -us -b
/usr/bin/apt -y install /home/${USER}/lirc-build/*.deb
/bin/cp /tmp/configs/denon.lircd.conf /etc/lirc/lircd.conf.d/
/bin/cp /home/${USER}/lirc-build/liblirc0_0.10.1-6.2~deb10u1_armhf.deb /
/bin/cp /home/${USER}/lirc-build/liblircclient0_0.10.1-6.2~deb10u1_armhf.deb /
/bin/cp /home/${USER}/lirc-build/lirc_0.10.1-6.2~deb10u1_armhf.deb /
cd /home/${USER}
/bin/rm -rf /home/${USER}/lirc-build
/bin/sed -i 's/driver = devinput/driver = default/' /etc/lirc/lirc_options.conf
/bin/sed -i 's/device = auto/device = \/dev\/lirc0/' /etc/lirc/lirc_options.conf
/bin/sed -i 's/#dtoverlay=gpio-ir,gpio_pin=17/dtoverlay=gpio-ir,gpio_pin=4/' /boot/config.txt

echo "==> Enabling hardware I2C and SPI"
/bin/sed -i 's/#dtparam=spi=on/dtparam=spi=on/' /boot/config.txt
/bin/sed -i 's/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/' /boot/config.txt

echo "==> Enabling SMB mount"
echo "/mnt /etc/auto.music --timeout 0 --browse" >> /etc/auto.master
/bin/cp /tmp/private/auto.music /etc/
/bin/chmod 640 /etc/auto.music

echo "==> Installing Python tools"
/usr/bin/apt -y install python3-pip

echo "==> Installing Minidisc library"
$AS /usr/bin/git clone https://github.com/pisarenko-net/md-uploader.git /home/${USER}/minidisc

echo "==> Installing CDP-SA software"
$AS /usr/bin/git clone https://github.com/pisarenko-net/cdp-sa.git /home/${USER}/cdp-sa
/usr/bin/apt -y install libboost-all-dev libdiscid-dev
/usr/bin/yes | /usr/bin/pip3 install zmq daemon python-daemon tornado transitions musicbrainzngs mutagen pyyaml ringbuf filelock pickledb discid coolname retrying miniaudio
/bin/cp /tmp/configs/cdp-sa.yaml /etc/
/bin/mkdir /var/run/cdp-sa
/bin/mkdir /var/log/cdp-sa
/bin/chown ${USER}:${USER} /var/run/cdp-sa /var/log/cdp-sa
/bin/cp /tmp/configs/systemd/* /etc/systemd/system/
/bin/systemctl daemon-reload
/bin/systemctl enable cdp_sa_commander
/bin/systemctl start cdp_sa_commander
/bin/systemctl enable cdp_sa_player
/bin/systemctl start cdp_sa_player
/bin/systemctl enable cdp_sa_ripper
/bin/systemctl start cdp_sa_ripper
/bin/systemctl enable cdp_sa_remote_control
/bin/systemctl start cdp_sa_remote_control
/bin/systemctl enable cdp_sa_display
/bin/systemctl start cdp_sa_display

echo '==> Cleaning up'
$AS /usr/bin/gpg --batch --delete-secret-keys B01ACF22C49D7DE67F625C6F538D8B004CA3C11A
/bin/rm -rf /tmp/scripts-repo
/bin/rm -rf /tmp/configs
/bin/rm -rf /tmp/private

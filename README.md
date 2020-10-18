# arch-bootstrap-scripts

Self-contained collection of setup scripts and configurations to build and deploy computers and network appliances from a bootable Arch thumb drive to a completely configured functioning state. The goal is to have disposable hardware that can be replaced with minimal effort and reasonable automation. Instead of doing backups and maintenance each machine is rebuilt from scratch on a whim. Everything is driven by software, nothing is installed manually.

There are two stages in this setup process:

 1. Bootstrap - a machine is completely wiped and a fresh copy of Arch is installed. Once the bootstrap completes the machine is bootable and reachable through SSH (certification-based authentication only). Bootstrap is started from the Arch installer.
 2. Stage 1 - machine is fully configured for its intended purpose. Stage 1 setup is initiated from the machine's terminal or through SSH once it successfully boots after the bootstrap.

Each device has its own folder with configuration files. Some configuration files are encrypted. The script will ask for a passphrase to unlock the files if that's the case.

Common scripts are placed in `common` folder. For example, the bootstrap is identical for every machine except for configuration variables. Similarly, `cli-layer` and `x-layer` install and configure tools I use on every Linux box.

# Devices

## NUC

Bootstrap (run from Arch installer as root):
```
$ curl -L git.io/apfel_nuc | sh
```

Stage 1 (run via SSH from the booted machine, after completing bootstrap):
```
$ curl -L git.io/apfel_nuc_install | sh
```

## Router

Bootstrap (run from Arch installer as root):
```
$ curl -L git.io/apfel_router | sh
```

Stage 1 (run via SSH from the booted machine, after completing bootstrap):
```
$ curl -L git.io/apfel_router_install | sh
```

## CD Player (cdp-sa)

CD Player doesn't run Arch and uses Raspberry OS instead. Because of that it doesn't share common scripts and instead has its own bootstrap and stage1.

Bootstrap (run from NOOBS SD card under root):
```
$ curl -L git.io/apfel_cdpsa | sh
```

Stage 1 (run via SSH from the booted machine, after completing bootstrap):
```
$ curl -L git.io/apfel_cdpsa_install | sh
```

Because the cdp-sa install doesn't copy OS files from the SD card and instead downloads OS every time I'm keeping a standard SD card with an automated script that installs the OS as soon as the system boots. To indicate successfull installation the green LED stays steady on.

The install script:
```
cat /usr/local/bin/install_cdp_sa.sh

#!/bin/bash
curl -L git.io/apfel_cdpsa | sh
```

The init script:
```
sudo systemctl edit --force --full install_cdp_sa.service

[Unit]
Description=Install cdp-sa software onto attached USB storage
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/pi
ExecStart=/usr/local/bin/install_cdp_sa.sh

[Install]
WantedBy=multi-user.target
```

And few additional commands:
```
$ sudo systemctl enable install_cdp_sa.service
$ sudo chmod +x /usr/local/bin/install_cdp_sa.service
```

With this setup to get the bootstrap stage complete all that is necessary is to insert the SD card and power cycle the Raspberry. Once the setup is complete green LED becomes steady. Note reboot isn't automatically performed as that would cause Raspberry to boot from SD again and reinstall again.

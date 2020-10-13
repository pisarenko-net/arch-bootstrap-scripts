# arch-bootstrap-scripts

Self-contained collection of setup scripts and configurations to build and deploy computers and network appliances from a bootable Arch thumb drive to a completely configured functioning state. The goal is to have disposable hardware that can be replaced with minimal effort and reasonable automation. Instead of doing backups and maintenance each machine is rebuilt from scratch on a whim. Everything is driven by software, nothing is installed manually.

There are two stages in this setup process:

 1. Bootstrap - a machine is completely wiped and a fresh copy of Arch is installed. Once the bootstrap completes the machine is bootable and reachable through SSH (certification-based authentication only). Bootstrap is started from the Arch installer.
 2. Stage 1 - machine is fully configured for its intended purpose. Stage 1 setup is initiated from the machine's terminal or through SSH once it successfully boots after the bootstrap.

Each device has its own folder with configuration files. Some configuration files are encrypted. The script will ask for a passphrase to unlock the files if that's the case.

Common scripts are placed in `common` folder. For example, the bootstrap is identical for every machine except for configuration variables. Similarly, `cli-layer` and `x-layer` install and configure tools I use on every Linux box.

# Devices

## NUC

Bootstrap (run from Arch installer):
```
$ curl -L git.io/apfel_nuc | sh
```

Stage 1 (run from the booted machine, after completing bootstrap):
```
$ curl -L git.io/apfel_nuc_install | sh
```

## Router

Bootstrap:
```
$ curl -L git.io/apfel_router | sh
```

Stage 1:
```
$ curl -L git.io/apfel_router_install | sh
```

## Hi-Fi appliance (cdp-sa)

Bootstrap (run from Arch installer):
```
$ curl -L git.io/apfel_cdpsa | sh
```

Stage 1 (run from the booted machine, after completing bootstrap):
```
$ curl -L git.io/apfel_cdpsa | sh
```

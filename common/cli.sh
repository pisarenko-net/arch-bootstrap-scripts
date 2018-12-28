#!/bin/bash

# run from bootstrapped machine: $ wget git.io/apfel_cli -O - | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/common/cli.sh" -F "code=apfel_cli")

export AS="/usr/bin/sudo -u ${USER}"

# enable time sync
echo "==> Enable time sync"
/usr/bin/timedatectl set-ntp true

# synchronize package database
echo "==> Refreshing pacman"
/usr/bin/pacman -Syu --noconfirm

# install tools
echo "==> Installing tools"
/usr/bin/pacman -S --noconfirm git htop net-tools tcpdump parted netcat tmux hwinfo zsh mc gnupg zip unrar wget linux-headers lsof dnsutils

# set nvim as default editor
echo "==> Setting default text editor"
/usr/bin/ln -sf /usr/bin/nvim /usr/bin/vi
/usr/bin/echo 'EDITOR=nvim' >> /etc/environment
/usr/bin/echo 'VISUAL=nvim' >> /etc/environment

# enable sudo for all members of group wheel
echo "==> Enable passwordless sudo for wheel group"
sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# update user
echo "==> Update user ${USER}"
/usr/bin/groupadd -r autologin
/usr/bin/usermod -G wheel,storage,power,autologin -s /bin/zsh ${USER}
cd /home/${USER}

# set git configuration
echo "==> Set git configuration"
$AS /usr/bin/git config --global user.email "${USER}@${DOMAIN}"
$AS /usr/bin/git config --global user.name "${FULL_NAME}"

# customize zsh
echo "==> Configure/customize shell"
$AS /usr/bin/rm .bash*
$AS /usr/bin/mkdir /home/${USER}/.cache
$AS /usr/bin/git clone https://aur.archlinux.org/oh-my-zsh-git.git
cd oh-my-zsh-git
$AS /usr/bin/makepkg -si --noconfirm
$AS /usr/bin/cp /usr/share/oh-my-zsh/zshrc /home/${USER}/.zshrc
cd ..
/usr/bin/rm -rf oh-my-zsh-git
/usr/bin/touch /home/${USER}/.zsh{rc,env}
/usr/bin/chown ${USER}:users /home/${USER}/.zsh{rc,env}
/usr/bin/echo 'unsetopt share_history' >> /home/${USER}/.zshenv
/usr/bin/echo 'export HISTFILE="$HOME/.zsh_history"' >> /home/${USER}/.zshenv
/usr/bin/echo 'export HISTSIZE=10000000' >> /home/${USER}/.zshenv
/usr/bin/echo 'export SAVEHIST=10000000' >> /home/${USER}/.zshenv

# set-up SSH keys
echo '==> Configuring SSH keys'
# TODO
$AS sh -c 'echo "github.com,192.30.253.113 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> /home/${USER}/.ssh/known_hosts'

# set-up PGP
# TODO

# custom configs
# TODO
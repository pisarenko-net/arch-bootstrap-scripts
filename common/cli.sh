#!/bin/bash

# run from bootstrapped machine: $ wget git.io/apfel_cli -O - | sh
# (created with: $ curl -i https://git.io -F "url=https://raw.githubusercontent.com/pisarenko-net/arch-bootstrap-scripts/master/common/cli.sh" -F "code=apfel_cli")

echo "==> Enable time sync"
/usr/bin/timedatectl set-ntp true

echo "==> Refreshing pacman"
/usr/bin/pacman -Syu --noconfirm

echo "==> Installing tools"
/usr/bin/pacman -S --noconfirm git htop net-tools tcpdump parted netcat tmux hwinfo zsh mc gnupg zip unrar wget linux-headers lsof dnsutils

echo "==> Setting default text editor"
/usr/bin/ln -sf /usr/bin/nvim /usr/bin/vi
/usr/bin/echo 'EDITOR=nvim' >> /etc/environment
/usr/bin/echo 'VISUAL=nvim' >> /etc/environment

echo "==> Enable passwordless sudo for wheel group"
/usr/bin/sed -i 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

echo "==> Update user ${USER}"
/usr/bin/groupadd -r autologin
/usr/bin/usermod -G wheel,storage,power,autologin -s /bin/zsh ${USER}
cd /home/${USER}

echo "==> Set git configuration"
$AS /usr/bin/git config --global user.email "${USER}@${DOMAIN}"
$AS /usr/bin/git config --global user.name "${FULL_NAME}"

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

echo '==> Configuring SSH keys'
$AS /usr/bin/mkdir /home/sergey/.ssh
$AS /usr/bin/cp /tmp/private/id_rsa /home/sergey/.ssh
$AS /usr/bin/cp /tmp/private/id_rsa.pub /home/sergey/.ssh
$AS /usr/bin/chmod 400 /home/sergey/.ssh/id_rsa
$AS sh -c 'echo "github.com,192.30.253.113 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> /home/${USER}/.ssh/known_hosts'

echo '==> Setting up custom settings'
cd /home/${USER}
$AS /usr/bin/mkdir .config
$AS /usr/bin/cp -r /tmp/configs/mc .config/
$AS /usr/bin/mkdir .config/nvim
$AS /usr/bin/cp -r /tmp/configs/nvim .config/nvim/init.vim
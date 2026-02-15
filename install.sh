#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

printf '%b\n' "${RED}\
                             ▄▄       ▄▄                                                      ▄▄    ▄▄       
  ▄▄▄█▀▀                 ▄███▀    ▄███▀       ██▀                                         ▄███▀   ▄█         
█████                   █████    █████       ███▄   ▄█▄   ▄█▄         ▄▄      ▄▄    ▄    █████   ████▄▄      
▀████           ▄▄      ▀████    ▀████      ▀█████▄█████▄████    ▄▄▄▄███▄   ▄▄███ ▄██▄   ▀████   ▀███████▄   
 ████ ▄██▄    ▄█████▄    ████     ████       ▀████  ████ ▀███▄  ████ ████▄ ▀▀████▄████▀   ████     ▀▀▀█████  
 ████▄████▄ ▄███▀████▄   ████     ████        ████  ████  ████  ████ █████   █████▀██▀    ████    ▄███ ▀████ 
 ████  ████ ████ ▀███▀   ████     ████        ████  ████  ████  ████ █████   █████ ▀      ████    ████  ████
 ████  ████ ████▄▀▀      ████     ████        ████  ████  ████  ████ ████▀   █████        ████    ████  ████ 
 ████  ████ ████▀        ████     ████       ▄████  ████▄ ███▀ ▄████▄████   ▄████▄ ▄▀     ████    ████  ███▀ 
 ████  ████ ▀████▄ ▄██  ▄████    ▄████       ▀████▀▀▀█████▀     ▀██████▀    ▀▀█████▀     ▄████   ▄████▄▄███  
▄████▄ ███▀  ▀██████▀   ▀████▀   ▀████▀        ▀▀     ▀▀          ▀█▀          ▀█▀       ▀████▀   ▀▀████▀▀   
 ▀█▀▀  ███     ▀██▀       ▀▀       ▀▀                                                      ▀▀        ▀▀      
      ▄██▀                                                                                                   
      ██                                                                                                     
    ▄▀${NC}"

read -p "${GREEN}Set up git? [Y/n] ${NC}" git
git=${git:-Y}

if [[ $git == [Yy] ]]; then
    read -p "${GREEN}Git username: ${NC}" GITUSER
    read -p "${GREEN}Git email: ${NC}" GITEMAIL
    git config --global user.name "$GITUSER"
    git config --global user.email "$GITEMAIL"
    git config --global init.defaultBranch main
fi

sudo pacman -Syu --noconfirm
sudo pacman -S --needed git rustup base-devel --noconfirm

# install yay
git clone "https://aur.archlinux.org/yay.git" &&
    cd "yay" &&
    makepkg -si --noconfirm &&
    cd .. &&
    rm -rf "yay"

# ssh keygen
if [ -f ~/.ssh/id_ed25519.pub ]; then
	echo "${RED}SSH key already exists ${NC}"
else
	read -p "${GREEN}Email address for ssh-keygen: ${NC}" email
	ssh-keygen -t ed25519 -C "$email"
fi

# mount nas
read -p "${GREEN}Mount raato? [Y/n] ${NC}" mount
mount=${mount:-Y}

if [[ $mount == [Yy] ]]; then
	read -p "${GREEN}Share username: ${NC}" USERNAME
	read -sp "${GREEN}Share password: ${NC}" PASSWORD
	echo

	SERVER="//192.168.1.12/raato"
	MOUNT_POINT="/mnt/raato"
	CREDENTIALS_FILE="/root/.smbcredentials"

	sudo mkdir -p "$MOUNT_POINT"

	sudo bash -c "echo -e 'username=$USERNAME\npassword=$PASSWORD' > $CREDENTIALS_FILE"
	sudo chmod 600 "$CREDENTIALS_FILE"

	sudo cp /etc/fstab /etc/fstab.bak

	FSTAB_LINE="$SERVER $MOUNT_POINT cifs credentials=$CREDENTIALS_FILE,uid=$(id -u),gid=$(id -g),iocharset=utf8 0 0"
	grep -qF -- "$FSTAB_LINE" /etc/fstab || echo "$FSTAB_LINE" | sudo tee -a /etc/fstab

	sudo mount -a
fi

# set up swapfile
sudo btrfs filesystem mkswapfile --size 16G /swap/swapfile
sudo swapon /swap/swapfile
SWAPLINE="/swap/swapfile none swap defaults 0 0"
grep -qF -- "$SWAPLINE" /etc/fstab || echo "$SWAPLINE" | sudo tee -a /etc/fstab

# set up snapper in a fucked up way
yay -S snapper

sudo umount /.snapshots 2>/dev/null || true
sudo rm -rf /.snapshots
sudo snapper -c root create-config /

if sudo btrfs subvolume show /.snapshots >/dev/null 2>&1; then
    sudo btrfs subvolume delete /.snapshots
fi

sudo mount /.snapshots
sudo chmod 750 /.snapshots
sudo chown root:users /.snapshots

sudo sed -i 's/^ALLOW_USERS=.*/ALLOW_USERS="emaj"/' /etc/snapper/configs/root
grep -q '^ALLOW_USERS=' /etc/snapper/configs/root || echo 'ALLOW_USERS="emaj"' | sudo tee -a /etc/snapper/configs/root

sudo sed -i 's/^SYNC_ACL=.*/SYNC_ACL="yes"/' /etc/snapper/configs/root
grep -q '^SYNC_ACL=' /etc/snapper/configs/root || echo 'SYNC_ACL="yes"' | sudo tee -a /etc/snapper/configs/root


# set up dcli
rustup default stable
yay -S dcli-arch-git --noconfirm
mkdir -p "${HOME}/.config"
git clone https://github.com/EMajesty/arch-config.git ~/.config/arch-config
dcli merge
dcli sync

echo -e "${RED}The pact is sealed ${NC}"

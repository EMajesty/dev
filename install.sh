#!/bin/bash

set -euo pipefail

# Ask for sudo once up front and keep it alive
sudo -v
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m' # No Color

# Hide stdout; keep stderr and prompts visible
LOG_FILE="${LOG_FILE:-/tmp/install.log}"
exec 3>&1
exec >"$LOG_FILE"

say() {
    printf '%b\n' "$1" >&2
}

prompt() {
    printf '%b' "$1" >/dev/tty
}

say "${BLUE}>> Logging output to ${LOG_FILE}${NC}"

SPINNER_PID=""
start_spinner() {
    local msg="$1"
    printf '%b' "${BLUE}>> ${msg}${NC} " >/dev/tty
    (
        local spin='-\|/'
        local i=0
        while true; do
            i=$(( (i + 1) % 4 ))
            printf '\b%s' "${spin:$i:1}" >/dev/tty
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}

stop_spinner() {
    local status="${1:-OK}"
    if [ -n "${SPINNER_PID}" ] && kill -0 "${SPINNER_PID}" 2>/dev/null; then
        kill "${SPINNER_PID}" 2>/dev/null || true
        wait "${SPINNER_PID}" 2>/dev/null || true
    fi
    SPINNER_PID=""
    printf '\b[%s]\n' "${status}" >/dev/tty
}

cleanup_spinner() {
    stop_spinner "FAIL"
}
trap cleanup_spinner EXIT

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

prompt "${GREEN}Set up git? [Y/n] ${NC}"
read -r git
git=${git:-Y}

if [[ $git == [Yy] ]]; then
    prompt "${GREEN}Git username: ${NC}"
    read -r GITUSER
    prompt "${GREEN}Git email: ${NC}"
    read -r GITEMAIL
    git config --global user.name "$GITUSER"
    git config --global user.email "$GITEMAIL"
    git config --global init.defaultBranch main
fi

start_spinner "Updating packages..."
sudo pacman -Syu --noconfirm
stop_spinner "OK"

start_spinner "Installing base packages..."
sudo pacman -S --needed git rustup base-devel openssh cifs-utils --noconfirm
stop_spinner "OK"

# install yay
if command -v yay >/dev/null 2>&1; then
    say "${YELLOW}yay already installed; skipping${NC}"
else
    start_spinner "Installing yay..."
    if [ -d yay ]; then
        rm -rf yay
    fi

    git clone "https://aur.archlinux.org/yay.git" &&
        cd "yay" &&
        makepkg -si --noconfirm &&
        cd .. &&
        rm -rf "yay"
    stop_spinner "OK"
fi

# ssh keygen
if [ -f ~/.ssh/id_ed25519.pub ]; then
	say "${YELLOW}SSH key already exists ${NC}"
else
	prompt "${GREEN}Email address for ssh-keygen: ${NC}"
	read -r email
	ssh-keygen -t ed25519 -C "$email"
fi

# mount nas
prompt "${GREEN}Mount raato? [Y/n] ${NC}"
read -r mount
mount=${mount:-Y}

if [[ $mount == [Yy] ]]; then
	prompt "${GREEN}Share username: ${NC}"
	read -r USERNAME
	prompt "${GREEN}Share password: ${NC}"
	read -rs PASSWORD
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
start_spinner "Creating swapfile..."
sudo btrfs filesystem mkswapfile --size 16G /swap/swapfile
sudo swapon /swap/swapfile
SWAPLINE="/swap/swapfile none swap defaults 0 0"
grep -qF -- "$SWAPLINE" /etc/fstab || echo "$SWAPLINE" | sudo tee -a /etc/fstab
stop_spinner "OK"

# set up snapper in a fucked up way
start_spinner "Installing snapper..."
yay -S --needed snapper --noconfirm
stop_spinner "OK"

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
start_spinner "Setting up dcli..."
rustup default stable
yay -S --needed dcli-arch-git --noconfirm
mkdir -p "${HOME}/.config"
git clone https://github.com/EMajesty/arch-config.git ~/.config/arch-config
dcli merge
dcli sync
stop_spinner "OK"

say "${RED}The pact is sealed ${NC}"

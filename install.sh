#!/bin/bash

PACKAGES=(
	7zip
	amd-ucode
	blueman
	btop
	clang
	cmake
	curl
	efibootmgr
	eom
	fastfetch
	ffmpegthumbnailer
	firefox
	freerdp
	galculator
	gdb
	ghostty
	git
	hyprland
	hyprpicker
	less
	ly
	mako
	mpc
	mpd
	ncmpc
	neovim
	networkmanager
	noto-fonts
	noto-fonts-cjk
	ntfs-3g
	obsidian
	openssh
	pavucontrol
	pipewire
	pipewire-alsa
	pipewire-jack
	pipewire-pulse
	pipewire-roc
	pipewire-v4l2
	python
	python-pip
	qbittorrent
	ranger
	remmina
	rustup
	smbclient
	stow
	swww
	telegram-desktop
	thunar
	tldr
	tmux
	tree
	tumbler
	udiskie
	unzip
	waybar
	wget
	wireplumber
	wofi
	xdg-desktop-portal
	xdg-desktop-portal-hyprland
	zsh 
)

AUR_PACKAGES=(
    discord-canary
    hyprshot
    mullvad-vpn
    vial-appimage
    whatsapp-for-linux
    yay
)

sudo pacman -Syu

mapfile -t INSTALLED < <(pacman -Qq)

# install packages
for pkg in "${PACKAGES[@]}"; do
	if ! [[ " ${INSTALLED[*]} " == *" $pkg"* ]]; then
 		sudo pacman -S --noconfirm ${pkg}
	fi
done

git config --global init.defaultBranch main

# import pgp keys
wget https://mullvad.net/media/mullvad-code-signing.asc
gpg --import mullvad-code-signing.asc
rm mullvad-code-signing.asc

# install aur packages
for pkg in "${AUR_PACKAGES[@]}"; do
	if ! [[ " ${INSTALLED[*]} " == *" $pkg"* ]]; then
	    git clone "https://aur.archlinux.org/${pkg}.git" &&
	    cd "$pkg" &&
	    makepkg -si --noconfirm &&
	    cd .. &&
	    rm -rf "$pkg"
	fi
done

# install stuff with scripts
if [ -d ~/.oh-my-zsh ]; then
	echo "Oh My ZSH is already installed"
else
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# systemd stuff
sudo systemctl enable --now ly.service
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now mullvad-daemon.service
systemctl enable --now --user mpd.service

# dotfiles stuff
# git clone https://github.com/emajesty/dotfiles
# cd dotfiles
# stow .
# cd

# ssh keygen
if [ -f ~/.ssh/id_ed25519.pub ]; then
	echo "SSH key already exists"
else
	read -p "Email address for ssh-keygen: " email
	ssh-keygen -t ed25519 -C "$email"
fi

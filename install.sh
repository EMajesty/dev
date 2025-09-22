#!/bin/bash

PACKAGES=(
	7zip
	amd-ucode
    ark
    aseprite
    blender
	blueman
	btop
	clang
	cmake
	curl
	discord
	dolphin
	efibootmgr
	eom
	fastfetch
	ffmpegthumbnailer
	ffmpegthumbs
	foliate
	freerdp
	galculator
	gdb
	ghostty
	git
    godot
	hyprland
	hyprpicker
	kdegraphics-thumbnailers
    kicad
    kicad-library
	kimageformats
    lazygit
	less
	lib32-mesa
	lib32-vulkan-radeon
	ly
	mako
	man-db
	mesa
	mpc
	mpd
	ncmpc
	neovim
	networkmanager
	noto-fonts
	noto-fonts-cjk
	ntfs-3g
    nwg-look
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
    qemu-full
	qt5-imageformats
    qt6ct
	ranger
	remmina
	rustup
	smbclient
	steam
	stow
    swtpm
	swww
	telegram-desktop
	thunar
	tldr
	tmux
	tree
    ttf-liberation
	tumbler
	udiskie
	unzip
    virt-manager
	vlc
	vulkan-radeon
	waybar
	wget
	wireplumber
	wofi
	xdg-desktop-portal
	xdg-desktop-portal-hyprland
	xf86-video-amdgpu
	zsh 
)

AUR_PACKAGES=(
    hyprshot
    # mullvad-vpn
    spotify
    trenchbroom-bin
    vial-appimage
    virtio-win
    whatsapp-for-linux
    yay
    zen-browser-bin
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
# wget https://mullvad.net/media/mullvad-code-signing.asc
# gpg --import mullvad-code-signing.asc
# rm mullvad-code-signing.asc

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

read -p "Mount raato? [Y/n] " yn
yn=${yn:-Y}
if [[ $yn == [Yy] ]]; then
	read -p "Share username: " USERNAME
	read -sp "Share password: " PASSWORD
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

# systemd stuff
sudo systemctl enable --now ly.service
# sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
# sudo systemctl enable --now mullvad-daemon.service
systemctl enable --now --user mpd.service
sudo systemctl enable --now libvirtd

# install stuff with scripts
if [ -d ~/.oh-my-zsh ]; then
	echo "Oh My ZSH is already installed"
else
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo -e "\e[31mThe pact is sealed\e[0m"

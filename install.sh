#!/bin/bash

CORE_PACKAGES=(
	7zip
    alacritty
    ark
    blueberry
    bluez
	btop
    cifs-utils
	clang
	cmake
    cups
    cups-pdf
    cups-filters
    cups-browsed
    system-config-printer
	curl
	discord
	efibootmgr
	eom
    eza
	fastfetch
	ffmpegthumbnailer
	ffmpegthumbs
	freerdp
	gdb
	ghostty
	git
    hypridle
	hyprland
    hyprlock
	hyprpicker
    hyprshot
    lazygit
	less
	lib32-mesa
    lua
    luajit
    luarocks
	mako
	man-db
	mesa
    nautilus
	neovim
    network-manager-applet
	networkmanager
	noto-fonts
	noto-fonts-cjk
	noto-fonts-emoji
	noto-fonts-extra
	ntfs-3g
    nwg-look
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
	rustup
	smbclient
	stow
	tldr
	tmux
	tree
    ttf-liberation
	tumbler
	udiskie
	unzip
	vlc
    vlc-plugins-all
	waybar
	wget
    wiremix
	wireplumber
	wofi
	xdg-desktop-portal
	xdg-desktop-portal-hyprland
	zsh 
    hyprshot
    mullvad-vpn
    plymouth-git
    runelite
    spotify
    zen-browser-bin
    swww
    waytrogen
    )

LAPTOP_PACKAGES=(
	amd-ucode
	lib32-vulkan-radeon
	vulkan-radeon
	xf86-video-amdgpu
    )

DESKTOP_PACKAGES=(
	amd-ucode
    aseprite
    bitwig-studio
    blender
    bottles
	foliate
    gamemode
    godot
    kicad
    kicad-library
	lib32-vulkan-radeon
	mpd
    mpd-mpris
    obs-studio
	obsidian
	qbittorrent
    qemu-full
	remmina
	rmpc
	steam
    swtpm
	telegram-desktop
    virt-manager
	vulkan-radeon
    wine
    winetricks
	xf86-video-amdgpu
    yabridge
    yabridgectl
    trenchbroom-bin
    tuxguitar
    vial-appimage
    virtio-win
    whatsdesk-bin
    )

read -p "Install desktop packages? [Y/n] " desktoppkgs 
desktoppkgs=${yn:-Y}

read -p "Install laptop packages? [Y/n] " laptoppkgs
laptoppkgs=${yn:-Y}

read -p "Set up git? [Y/n] " git
git=${yn:-Y}

if [[ $git == [Yy] ]]; then
    read -p "Git username: " GITUSER
    read -p "Git email: " GITEMAIL
    git config --global user.name "$GITUSER"
    git config --global user.email "$GITEMAIL"
    git config --global init.defaultBranch main
fi

sudo pacman -Syu --noconfirm

# install yay
git clone "https://aur.archlinux.org/yay.git" &&
    cd "yay" &&
    makepkg -si --noconfirm &&
    cd .. &&
    rm -rf "yay"

mapfile -t INSTALLED < <(pacman -Qq)

# install packages
for pkg in "${CORE_PACKAGES[@]}"; do
	if ! [[ " ${INSTALLED[*]} " == *" $pkg"* ]]; then
 		yay -S --noconfirm ${pkg}
	fi
done

if [[ $desktoppkgs == [Yy] ]]; then
    for pkg in "${DESKTOP_PACKAGES[@]}"; do
        if ! [[ " ${INSTALLED[*]} " == *" $pkg"* ]]; then
            yay -S --noconfirm ${pkg}
        fi
    done
fi

if [[ $laptoppkgs == [Yy] ]]; then
    for pkg in "${LAPTOP_PACKAGES[@]}"; do
        if ! [[ " ${INSTALLED[*]} " == *" $pkg"* ]]; then
            yay -S --noconfirm ${pkg}
        fi
    done
fi

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
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now mullvad-daemon.service

if [[ $desktoppkgs == [Yy] ]]; then
    systemctl enable --now --user mpd.service
    systemctl enable --now --user mpd-mpris.service
    sudo systemctl enable --now libvirtd
fi

# install stuff with scripts
if [ -d ~/.oh-my-zsh ]; then
	echo "Oh My ZSH is already installed"
else
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo -e "\e[31mThe pact is sealed\e[0m"

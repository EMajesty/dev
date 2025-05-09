#!/bin/bash

echo "Hell World"

AUR_PACKAGES=(
    discord-canary
)

for pkg in "${AUR_PACKAGES[@]}"; do
    git clone "https://aur.archlinux.org/${pkg}.git"
    cd "$pkg"
    makepkg -si --noconfirm
    cd ..
    rm -rf "$pkg"
done

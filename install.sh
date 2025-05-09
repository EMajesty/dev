#!/bin/bash

while true; do
    read -p "Enter username: " user

    while true; do
        read -s -p "Enter password: " password
        echo
        read -s -p "Confirm password: " password2
        echo

        if [[ "$password" == "$password2" ]]; then
            break
        else
            echo "Password mismatch. Try again."
        fi
    done

    read -p "Enter hostname: " hostname
    echo "Using "$user" as username"
    echo "Using "$hostname" as hostname"
    read -p "Is this okay? [Y/n] " answer
    answer=${answer:-Y}

    if [[ "$answer" =~ ^[Yy] ]]; then
        break
    fi
done

echo "Hell World"

AUR_PACKAGES=(
    discord-canary
    hyprland-git
    hyprshot
    mullvad-vpn
)

# su - $user -c "echo $user && whoami"
# for pkg in "${AUR_PACKAGES[@]}"; do
#     su - $user -c "
#     git clone "https://aur.archlinux.org/${pkg}.git" &&
#     cd "$pkg" &&
#     echo "$password" | makepkg -si --noconfirm &&
#     cd .. &&
#     rm -rf "$pkg"
#     "
# done

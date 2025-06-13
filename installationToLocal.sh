#!/bin/bash

echo "Importation des configs"
# Copier les configurations depuis le répertoire courant vers ~/.config
cp -r config/hyprland/.config/dunst ~/.config/
cp -r config/hyprland/.config/waybar ~/.config/
cp -r config/hyprland/.config/rofi ~/.config/
cp -r config/hyprland/.config/hypr ~/.config/
cp -r config/hyprland/.config/nvim ~/.config/

cp -r config/kitty ~/.config/

cp -r config/git/.gitconfig ~/.gitconfig
echo "Importaion des configs OK"
echo "Installation des packages"

for x in $(cat installed_package_list.txt); do
  yay -S --needed $x 2>/dev/null | grep -v -e "est à jour -- ignoré" -e " il n’y a rien à faire" -e "il n'y a rien à faire" -e "Sync Explicit"
done

echo "Installation des packages OK"

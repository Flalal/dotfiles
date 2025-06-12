#!/bin/bash

# Copier les configurations depuis le répertoire courant vers ~/.config
cp -r config/hyprland/.config/dunst ~/.config/
cp -r config/hyprland/.config/waybar ~/.config/
cp -r config/hyprland/.config/rofi ~/.config/
cp -r config/hyprland/.config/hypr ~/.config/
cp -r config/hyprland/.config/nvim ~/.config/

cp -r config/kitty ~/.config/

cp -r config/git/.gitconfig ~/.gitconfig
echo "Les configurations ont été exportées vers ~/.config."


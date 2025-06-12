#!/bin/bash

# Copier les configurations depuis le répertoire courant vers ~/.config
cp -r config/hyprland/dunst ~/.config/
cp -r config/hyprland/waybar ~/.config/
cp -r config/hyprland/rofi ~/.config/
cp -r config/hyprland/hypr ~/.config/
cp -r config/hyprland/nvim ~/.config/
cp config/git/.gitconfig ~/.gitconfig
echo "Les configurations ont été exportées vers ~/.config."


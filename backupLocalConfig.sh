#!/bin/bash

echo "Hyprland backup"
cp -r ~/.config/dunst config/hyprland/.config/
cp -r ~/.config/waybar config/hyprland/.config/
cp -r ~/.config/rofi config/hyprland/.config/
cp -r ~/.config/hypr config/hyprland/.config/
cp -r ~/.config/nvim config/hyprland/.config/
cp -r ~/.config/kitty config/
echo "Mimeapps backup"
cp ~/.config/mimeapps.list config/mimeapps

echo "Image backup"
cp ~/Images/wallpaper.jpg Images/wallpaper.jpg

echo "Git backup"
cp ~/.gitconfig config/git/
echo "Zsh backup"
cp ~/.zshrc config/zsh
echo "Mimeapps backup"

echo "Les configurations ont été copiées dans le répertoire courant."


#!/bin/bash

cp -r ~/.config/dunst config/hyprland/.config/
cp -r ~/.config/waybar config/hyprland/.config/
cp -r ~/.config/rofi config/hyprland/.config/
cp -r ~/.config/hypr config/hyprland/.config/
cp -r ~/.config/nvim config/hyprland/.config/
cp -r ~/.config/kitty config/
cp ~/.gitconfig config/git/
cp ~/.zshrc config/zsh
echo "Les configurations ont été copiées dans le répertoire courant."


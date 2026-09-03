#!/usr/bin/env bash
# Pose les liens du shell et le marqueur de machine.
#   ./install.sh mac
#   ./install.sh workstation
#
# Idempotent : relancé, il ne fait rien s'il n'y a rien à faire. Un fichier
# réel déjà en place est sauvegardé avant d'être remplacé par le lien ; un lien
# déjà correct est laissé tel quel.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
machine="${1:-}"

if [ -z "$machine" ]; then
  echo "usage: $0 <machine>" >&2
  echo "machines disponibles : $(cd "$repo/zshrc.d" && ls *.zsh | sed 's/\.zsh$//' | tr '\n' ' ')" >&2
  exit 1
fi

fragment="$repo/zshrc.d/$machine.zsh"
if [ ! -f "$fragment" ]; then
  echo "fragment inconnu : $fragment" >&2
  echo "machines disponibles : $(cd "$repo/zshrc.d" && ls *.zsh | sed 's/\.zsh$//' | tr '\n' ' ')" >&2
  exit 1
fi

# Le dépôt doit être en ~/dotfiles : c'est le chemin que le socle utilise pour
# retrouver son fragment de machine.
if [ "$repo" != "$HOME/dotfiles" ]; then
  echo "⚠  le dépôt est en $repo, le socle attend $HOME/dotfiles" >&2
  exit 1
fi

link() {
  local src="$1" dest="$2"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "   déjà lié : $dest"
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local backup="$dest.bak-$(date +%Y-%m-%d-%H%M%S)"
    mv "$dest" "$backup"
    echo "   sauvegardé : $backup"
  fi

  ln -s "$src" "$dest"
  echo "   lié : $dest → $src"
}

echo "dotfiles → $machine"
link "$repo/zshrc" "$HOME/.zshrc"
link "$repo/p10k.zsh" "$HOME/.p10k.zsh"

marker_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles"
mkdir -p "$marker_dir"
printf '%s\n' "$machine" > "$marker_dir/machine"
echo "   marqueur : $marker_dir/machine = $machine"

# Les secrets ne sont pas dans le dépôt (cf. README). Sans le fichier, le shell
# démarre quand même — mais claude-pro et litellm-budget échouent en silence.
# Seul le Mac en attend : ailleurs, l'absence est normale et ne mérite pas
# d'avertissement à chaque déploiement.
if [ "$machine" = "mac" ] && [ ! -f "$HOME/.zshrc.secrets" ]; then
  echo "⚠  ~/.zshrc.secrets absent — cf. README.md pour les variables attendues"
fi

echo "fait. Ouvrir un nouveau shell, ou : exec zsh"

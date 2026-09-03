# Socle commun — Mac, workstation (CT 700), Windows à terme.
# Ce fichier est un lien vers ~/dotfiles/zshrc, posé par install.sh.
# Rien de spécifique à une machine ici : cela va dans zshrc.d/<machine>.zsh.

# Prompt instantané de powerlevel10k. Doit rester tout en haut : tout ce qui
# peut demander une saisie (mot de passe, [y/n]) doit passer AVANT.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- oh-my-zsh ---------------------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Les plugins sont retenus s'ils existent : la liste est la même partout, mais
# une machine qui n'a pas docker ou fluxcd ne doit pas afficher d'avertissement
# au démarrage. `plugins` doit être fixé avant le source d'oh-my-zsh.
plugins=(git)
for _p in zsh-autosuggestions zsh-syntax-highlighting docker fzf asdf fluxcd; do
  if [[ -d "$ZSH/plugins/$_p" || -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/$_p" ]]; then
    plugins+=("$_p")
  fi
done
unset _p

source "$ZSH/oh-my-zsh.sh"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- Alias ------------------------------------------------------------------

# eza n'existe pas partout : sans lui, `ls` doit rester `ls`.
if command -v eza >/dev/null; then
  alias ls="eza --long --header --git --icons"
  alias ll="eza --long --header --git --icons --extended"
fi

alias k="kubectl"
alias kgp="k get pods"
alias kgs="k get services"
alias kgsts="k get sts"
alias kgd="k get deployments"
alias kgin="k get ingress"
alias kghpa="k get hpa"
alias kgpv="k get pv"
alias kgpvc="k get pvc"
alias kgsecret='f() { kubectl get secret "$1" -o go-template="{{range \$k,\$v := .data}}{{printf \"%s=\" \$k}}{{\$v|base64decode}}{{printf \"\n\"}}{{end}}"; }; f'
alias klo="k logs -f"
alias kns="kubens"
alias kctx="kubectx"

alias untar="tar -xvf"
alias jwt-decode="jq -R 'split(\".\") | .[1] | @base64d | fromjson'"

# Le vault est au même endroit sur les deux machines. Sur la workstation,
# `claude` est une fonction (cf. zshrc.d/workstation.zsh) et non le binaire.
alias cc="cd ~/Documents/obsidian && claude"

export EDITOR="nvim"

# --- Fonctions ---------------------------------------------------------------

git_pull_all() {
    for dir in */; do
        if [ -d "$dir/.git" ]; then
            echo "Mise à jour de $dir"
            (cd "$dir" && git pull --rebase)
        fi
    done
}

git_commit_all() {
    if [ -z "$1" ]; then
        echo "Message needed"
        return 1
    fi

    local message="$1"

    for dir in */; do
        if [ -d "$dir/.git" ]; then
            echo "Commit $dir"
            (cd "$dir" && git add . && git commit -m "$message" && git push)
        fi
    done
}

# Clone un repo git dans une arborescence organisée :
#   ~/${GIT_PROJECT_WORKSPACE:-dev}/<domaine-slugifié>/<path>
# (les domaines Auchan sont forcés sur le slug + endpoint internal)
clone() {
  local url="$1"
  if [ -z "$url" ]; then
    echo "usage: clone <git-url>" >&2
    return 1
  fi

  local domain repopath
  if [[ "$url" == git@*:* ]]; then
    domain="${url#git@}"; domain="${domain%%:*}"
    repopath="${url#*:}"; repopath="${repopath%.git}"
  elif [[ "$url" == https://* ]]; then
    local rest="${url#https://}"
    domain="${rest%%/*}"
    repopath="${rest#*/}"; repopath="${repopath%.git}"
  else
    echo "URL non supportée : $url" >&2
    return 1
  fi

  local clone_url="$url" slug
  if [[ "$domain" == "git.auchan.com" || "$domain" == "git.internal.auchan.com" ]]; then
    slug="git-internal-auchan-com"
    clone_url="git@git.internal.auchan.com:${repopath}.git"
  else
    slug="${domain//./-}"
  fi

  local base="$HOME/${GIT_PROJECT_WORKSPACE:-dev}"
  local dest="$base/$slug/$repopath"
  local parent="${dest%/*}"

  if [ -d "$dest" ]; then
    if git -C "$dest" rev-parse --git-dir >/dev/null 2>&1; then
      echo "📦 Déjà cloné, git pull → $dest"
      git -C "$dest" pull
    else
      echo "⚠️  $dest existe mais n'est pas un repo git" >&2
      return 1
    fi
    return
  fi

  mkdir -p "$parent" || return 1
  git -C "$parent" clone "$clone_url" || return 1
  echo "✅ Cloné dans $dest"
  echo "   cd $dest"
}

# fcd — fuzzy cd (Jeremy Fossette, 2026-06-02)
fcd() {
  local dir preview
  # lsd n'est pas partout ; sans lui, l'aperçu retombe sur ls.
  if command -v lsd >/dev/null; then
    preview='lsd --tree --depth 1 --color always {}'
  else
    preview='ls -la {}'
  fi
  dir=$(fd --type d --hidden --exclude .git ${1:+--max-depth "$1"} . 2>/dev/null \
    | fzf --height 60% --reverse --border \
          --preview "$preview" \
          --preview-window 'right,50%') \
    && cd "$dir"
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# --- Secrets -----------------------------------------------------------------

# Tokens et mots de passe : hors du dépôt, jamais suivis, propres à la machine.
# git.home miroite vers un GitHub public — ce qui entre ici en sortirait.
# Cf. README.md pour la liste des variables attendues.
[ -f ~/.zshrc.secrets ] && source ~/.zshrc.secrets

# --- Fragment de machine -----------------------------------------------------

# Le nom vient d'un marqueur posé par install.sh, jamais de `hostname` :
# netslope s'appelle « florian-PC », et le déguisement d'une machine n'a pas à
# décider de sa configuration.
_dotfiles_machine_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/machine"
if [ -r "$_dotfiles_machine_file" ]; then
  _dotfiles_machine="$(cat "$_dotfiles_machine_file")"
  [ -f "$HOME/dotfiles/zshrc.d/${_dotfiles_machine}.zsh" ] \
    && source "$HOME/dotfiles/zshrc.d/${_dotfiles_machine}.zsh"
  unset _dotfiles_machine
else
  print -P "%F{yellow}⚠  dotfiles : marqueur de machine absent → ~/dotfiles/install.sh <machine>%f"
fi
unset _dotfiles_machine_file

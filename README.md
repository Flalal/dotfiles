# dotfiles

Le même shell sur toutes les machines : zsh, oh-my-zsh, powerlevel10k.

```
zshrc                 socle commun
zshrc.d/mac.zsh       Homebrew, Auchan, VPN maison
zshrc.d/workstation.zsh   CT 700 — Claude Code, bascules de télémétrie
p10k.zsh              thème du prompt
install.sh            pose les liens et le marqueur de machine
```

## Installation

```sh
git clone git.home:dotfiles ~/dotfiles
~/dotfiles/install.sh mac          # ou : workstation
exec zsh
```

Le dépôt doit être en `~/dotfiles` — c'est le chemin par lequel le socle
retrouve son fragment. `install.sh` refuse de s'exécuter ailleurs.

Il sauvegarde tout fichier réel qu'il remplace (`.bak-<horodatage>`) et ne
touche pas à un lien déjà correct.

## Le fragment de machine

Le socle choisit son fragment sur `~/.config/dotfiles/machine`, écrit par
`install.sh`. **Jamais sur `hostname`** : netslope s'appelle `florian-PC`, et le
déguisement d'une machine n'a pas à décider de sa configuration.

Marqueur absent → le shell démarre quand même, avec un avertissement.

## Secrets

Ils vivent dans `~/.zshrc.secrets`, **hors du dépôt** : `git.home` miroite
quotidiennement vers un GitHub public. Le socle le source s'il existe.

Variables attendues (macOS) :

| Variable | Usage |
|---|---|
| `AUCHAN_LITELLM_KEY` | `claude-pro`, `litellm-budget` |
| `JIRA_API_TOKEN` | jira-cli |
| `HELM_REPO_USERNAME` / `HELM_REPO_PASSWORD` | dépôt Helm auchanlab |

Sans le fichier, le shell démarre normalement : seules ces commandes-là
échouent.

## Dépendances

Le socle dégrade proprement quand un outil manque — `eza`, `lsd`, `fzf`, `fd`
et les plugins oh-my-zsh sont tous testés avant usage. Une machine minimale
obtient donc un shell fonctionnel, pas une erreur au démarrage.

Sur la workstation, l'installation est faite par le rôle Ansible `workstation`
de `home-servers` : paquets, clones épinglés d'oh-my-zsh et du thème, puis ce
`install.sh`.

## Versions

powerlevel10k et les deux plugins zsh sont suivis par
`scripts/check-versions.py` dans `home-servers`. oh-my-zsh ne publie pas de
release : il est épinglé sur un commit, et figure parmi les exceptions
documentées de ce script.

## Ce qui n'est pas ici

`~/.zshenv` (Volta, cargo, `GITLAB_HOST`) reste propre au Mac et non suivi : il
s'exécute pour tout shell, y compris non interactif, et une erreur y casse
`ssh <machine> <commande>` sans message lisible.

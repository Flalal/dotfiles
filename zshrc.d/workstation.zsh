# Fragment workstation — CT 700, Debian 13. Reprise de ce que portait ~/.bashrc.

# Claude Code est installé sous le préfixe npm du compte, pas dans /usr/local :
# l'outil doit pouvoir réécrire son propre paquet sans qu'un répertoire système
# change de propriétaire. Le rôle Ansible pose aussi un lien dans /usr/local/bin
# pour les shells non interactifs ; le PATH ci-dessous sert au reste des paquets
# globaux installés depuis ce compte.
export PATH="$HOME/.npm-global/bin:$PATH"

# Les shims d'asdf, par lesquels `java` et `mvn` existent. Placés APRÈS le
# préfixe npm dans le fichier, donc devant lui dans le PATH — sans conséquence :
# asdf ne porte ici ni `nodejs` ni `python`, et la garde du rôle l'interdit.
export PATH="$HOME/.asdf/shims:$PATH"

# La télémétrie Auchan est déclarée dans settings.json, partagé par git avec le
# Mac. Elle est neutralisée ici par --settings, seul niveau de précédence
# au-dessus des fichiers (hors managed) : il n'existe pas de settings.local.json
# au niveau utilisateur, contrairement au niveau projet.
# Coupée par défaut ; `telemetry-on` la réactive pour le shell courant.
: "${CC_TELEMETRY:=off}"

claude() {
  if [ "$CC_TELEMETRY" = "on" ]; then
    command claude "$@"
  else
    command claude --settings "$HOME/.claude/telemetry-off.json" "$@"
  fi
}

telemetry-on()     { export CC_TELEMETRY=on;  echo "télémétrie Auchan ACTIVÉE (shell courant)"; }
telemetry-off()    { export CC_TELEMETRY=off; echo "télémétrie coupée (shell courant)"; }
telemetry-status() { echo "CC_TELEMETRY=$CC_TELEMETRY"; }

# ── Mode Auchan ───────────────────────────────────────────────────────────────
#
# Une seule bascule pour « je travaille pour Auchan » : le proxy corp et la
# télémétrie ensemble. Les commandes telemetry-* restent utilisables seules —
# voir l'avertissement plus bas, qui est la raison de les garder.
#
# Cette machine sert à la fois au parc perso et au travail. Le proxy n'est donc
# JAMAIS posé globalement : un HTTPS_PROXY dans /etc/profile.d enverrait le
# trafic personnel — git.home, GitHub, `tofu plan` sur le Proxmox — par le
# proxy d'entreprise. La bascule est explicite et ne vaut que pour le shell
# courant, sur le modèle de telemetry-on/off ci-dessus.
#
# Il est indispensable côté Auchan : les control planes GKE sont sur des
# endpoints PRIVÉS (10.189.x) qui ne répondent qu'à travers le tunnel Netskope.
# L'authentification gcloud, elle, passe en direct.
#
# :3128 est le port unique de la VM relais — internet public, SaaS,
# git.auchan.com et les internes 10.x (yoda, ai-gateway, registry ecom, kiwi).
AUCHAN_PROXY="http://10.0.2.87:3128"

# Le /24 de la maison sort du proxy : le parc perso doit rester en direct. La
# plage est volontairement étroite — les clusters GKE sont en 10.189.x, et un
# 10.0.0.0/8 les ferait sortir du proxy, donc échouer.
AUCHAN_NO_PROXY="localhost,127.0.0.1,::1,.home,.local,10.0.2.0/24"

# AVERTISSEMENT : `auchan-on` allume aussi la télémétrie. Dans un tel shell,
# lancer `claude` sur le vault ou un projet perso enverrait cet usage au
# collecteur d'Auchan. `telemetry-off` la recoupe sans toucher au proxy — d'où
# le maintien des deux commandes séparées.
auchan-on() {
  export HTTPS_PROXY="$AUCHAN_PROXY"
  export HTTP_PROXY="$AUCHAN_PROXY"
  export NO_PROXY="$AUCHAN_NO_PROXY"
  export https_proxy="$HTTPS_PROXY" http_proxy="$HTTP_PROXY" no_proxy="$NO_PROXY"
  export CC_TELEMETRY=on
  echo "mode Auchan ACTIVÉ (shell courant)"
  echo "  proxy      $AUCHAN_PROXY"
  echo "  télémétrie activée — telemetry-off pour la couper seule"
}

auchan-off() {
  unset HTTPS_PROXY HTTP_PROXY NO_PROXY https_proxy http_proxy no_proxy
  export CC_TELEMETRY=off
  echo "mode Auchan coupé (shell courant) — proxy et télémétrie"
}

auchan-status() {
  if [ -n "$HTTPS_PROXY" ]; then
    echo "proxy      : $HTTPS_PROXY"
    echo "direct     : $NO_PROXY"
  else
    echo "proxy      : coupé"
  fi
  echo "télémétrie : $CC_TELEMETRY"
  command -v kubectl >/dev/null &&
    echo "contexte   : $(kubectl config current-context 2>/dev/null || echo aucun)"
}

# ── Claude Code par la passerelle interne d'Auchan ────────────────────────────
#
# Même bascule que sur le poste : Claude Code parle à LiteLLM
# (api-private-yoda) au lieu d'api.anthropic.com. La clé vient de
# ~/.zshrc.secrets, rendu par Ansible depuis sops.
#
# Deux écarts avec le poste, tous deux tenant à la machine :
#
#   - pas de NODE_TLS_REJECT_UNAUTHORIZED=0. Les autorités Netskope sont dans
#     le magasin du système et dans NODE_EXTRA_CA_CERTS : la chaîne se vérifie
#     pour de bon. Le poste, lui, désarme le contrôle faute de les avoir.
#
#   - tout se passe dans un SOUS-SHELL. Sur le poste, les exports survivent à
#     la commande : le shell reste ensuite pointé sur la passerelle d'Auchan,
#     et chaque `claude` suivant y part sans que rien ne le dise.
#
# La télémétrie est allumée pour cet appel-là seulement : l'usage EST celui
# d'Auchan, mais le shell appelant garde le sien.
claude-pro() {
  if [ -z "$AUCHAN_LITELLM_KEY" ]; then
    echo "AUCHAN_LITELLM_KEY absente de ~/.zshrc.secrets" >&2
    return 1
  fi
  (
    export ANTHROPIC_BASE_URL="https://api-private-yoda.ari.internal.auchan.com/corp/v2/aia"
    export ANTHROPIC_AUTH_TOKEN="$AUCHAN_LITELLM_KEY"
    export ANTHROPIC_MODEL="claude-sonnet-4-6"
    export ANTHROPIC_SMALL_FAST_MODEL="claude-sonnet-4-6"
    export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
    export HTTPS_PROXY="$AUCHAN_PROXY" HTTP_PROXY="$AUCHAN_PROXY"
    export NO_PROXY="$AUCHAN_NO_PROXY"
    export https_proxy="$AUCHAN_PROXY" http_proxy="$AUCHAN_PROXY"
    export no_proxy="$AUCHAN_NO_PROXY"
    export CC_TELEMETRY=on
    cd ~/Documents/obsidian && claude "$@"
  )
}

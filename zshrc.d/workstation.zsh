# Fragment workstation — CT 700, Debian 13. Reprise de ce que portait ~/.bashrc.

# Claude Code est installé sous le préfixe npm du compte, pas dans /usr/local :
# l'outil doit pouvoir réécrire son propre paquet sans qu'un répertoire système
# change de propriétaire. Le rôle Ansible pose aussi un lien dans /usr/local/bin
# pour les shells non interactifs ; le PATH ci-dessous sert au reste des paquets
# globaux installés depuis ce compte.
export PATH="$HOME/.npm-global/bin:$PATH"

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

# ── Proxy corp Auchan ─────────────────────────────────────────────────────────
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

auchan-on() {
  export HTTPS_PROXY="$AUCHAN_PROXY"
  export HTTP_PROXY="$AUCHAN_PROXY"
  export NO_PROXY="$AUCHAN_NO_PROXY"
  export https_proxy="$HTTPS_PROXY" http_proxy="$HTTP_PROXY" no_proxy="$NO_PROXY"
  echo "proxy Auchan ACTIVÉ (shell courant) — $AUCHAN_PROXY"
}

auchan-off() {
  unset HTTPS_PROXY HTTP_PROXY NO_PROXY https_proxy http_proxy no_proxy
  echo "proxy Auchan coupé (shell courant)"
}

auchan-status() {
  if [ -n "$HTTPS_PROXY" ]; then
    echo "proxy   : $HTTPS_PROXY"
    echo "direct  : $NO_PROXY"
  else
    echo "proxy   : coupé"
  fi
  command -v kubectl >/dev/null &&
    echo "contexte: $(kubectl config current-context 2>/dev/null || echo aucun)"
}

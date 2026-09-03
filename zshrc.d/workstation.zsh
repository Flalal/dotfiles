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

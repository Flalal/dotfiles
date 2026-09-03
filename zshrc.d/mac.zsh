# Fragment macOS — chemins Homebrew, outillage Auchan, VPN maison.
# Tout ce qui vit sous /opt/homebrew ou ~/Library appartient ici.
#
# L'ORDRE DES BLOCS EST SIGNIFIANT : chacun prépend au PATH, donc le dernier
# gagne. Il reproduit celui de l'ancien ~/.zshrc — vérifié par diff des deux
# environnements. En particulier, les shims d'asdf doivent rester derrière
# ~/.local/bin et Volta, sans quoi asdf décide de la version de node.

# --- Google Cloud ------------------------------------------------------------

_gcloud_sdk="$HOME/Documents/google-cloud-sdk"
[ -f "$_gcloud_sdk/path.zsh.inc" ] && . "$_gcloud_sdk/path.zsh.inc"
[ -f "$_gcloud_sdk/completion.zsh.inc" ] && . "$_gcloud_sdk/completion.zsh.inc"
unset _gcloud_sdk

# --- Gestionnaires de versions et SDK ---------------------------------------

[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh
[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ] && source "$HOME/.sdkman/bin/sdkman-init.sh"
[ -f /opt/homebrew/opt/asdf/libexec/asdf.sh ] && . /opt/homebrew/opt/asdf/libexec/asdf.sh

# --- PATH --------------------------------------------------------------------

[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ~/.local/bin doit précéder /opt/homebrew/bin pour que les wrappers maison
# gagnent (cf. ~/.local/bin/glab). Volta est posé dans ~/.zshenv.
export PATH="$HOME/.local/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# jira-cli
export PATH="$HOME/bin:$PATH"
[ -f ~/.gworkspace.sh ] && source ~/.gworkspace.sh

export PATH="$HOME/.opencode/bin:$PATH"
alias oc='OPENCODE_EXPERIMENTAL_PLAN_MODE=1 opencode'

# --- Auchan ------------------------------------------------------------------

alias runnettools="kubectl run ffltools --image=registry.auchanlab.com/digit/multitools:1.0.0 --rm -it --restart=Never --command -- /bin/sh"

# Netskope : VM relais 10.0.2.87. Le navigateur passe par la PAC
# (http://10.0.2.87:8080/corp.pac) ; les outils CLI ne lisent PAS la PAC.
#   :3128 = port unique — internet public + SaaS + git.auchan.com + bin/harbor
#           ET les internes 10.x (yoda, ai-gateway, registry ecom, dev-kiwi)
# Cf. ~/Documents/obsidian/auchan/3-ressources/netskope-vm-proxy-setup.md
auchan-status() { echo "IP publique vue : $(curl -s -m 5 https://ifconfig.me)"; }
alias resetpac='sudo networksetup -setautoproxystate "Wi-Fi" off && sudo networksetup -setautoproxystate "Wi-Fi" on'

# Interception TLS Netskope : le bundle d'entreprise pour tout l'outillage Node.
# Régénérer avec :
#   security find-certificate -a -p /Library/Keychains/System.keychain > ~/.config/certs/corporate-ca.pem
export NODE_EXTRA_CA_CERTS="$HOME/.config/certs/corporate-ca.pem"

# Claude Code via le proxy interne Auchan (api-private-yoda), dans le vault.
# La clé vient de ~/.zshrc.secrets.
claude-pro() {
    export ANTHROPIC_BASE_URL="https://api-private-yoda.ari.internal.auchan.com/corp/v2/aia"
    export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
    export ANTHROPIC_AUTH_TOKEN="$AUCHAN_LITELLM_KEY"
    export ANTHROPIC_MODEL="claude-sonnet-4-6"
    export ANTHROPIC_SMALL_FAST_MODEL="claude-sonnet-4-6"
    export NODE_TLS_REJECT_UNAUTHORIZED=0
    export HTTPS_PROXY="http://10.0.2.87:3128"
    export HTTP_PROXY="$HTTPS_PROXY"
    export NO_PROXY="localhost,127.0.0.1,.home,.local"

    cd ~/Documents/obsidian && claude "$@"
}

# Conso et budget restant sur l'instance LiteLLM Auchan
litellm-budget() {
    local BASE="https://ai-gateway.internal.auchan.com"
    curl -s -k -x http://10.0.2.87:3128 -H "Authorization: Bearer $AUCHAN_LITELLM_KEY" "$BASE/key/info" | \
        python3 -c "
import json, sys
d = json.load(sys.stdin)['info']
spend = d['spend']
budget = d['max_budget']
pct = spend / budget * 100 if budget else 0
reset = (d.get('budget_reset_at') or '')[:10]
print(f'spend: \${spend:.4f} / \${budget} ({pct:.1f}%) reset {reset}')
"
}

# --- VPN maison --------------------------------------------------------------

# wg-quick en CLI, à la place de WireGuard.app
export HOME_VPN_CONF="$HOME/Documents/perso/vpn/Home-MacPro.conf"

home-vpn-up()     { sudo wg-quick up "$HOME_VPN_CONF"; }
home-vpn-down()   { sudo wg-quick down "$HOME_VPN_CONF"; }
home-vpn-status() { sudo wg show; }

# --- Statut de session gcloud au démarrage (Jeremy Fossette, 2026-08-27) -----

# Nécessite gtimeout (brew install coreutils).
gtimeout -k 1 2 gcloud auth print-access-token >/dev/null 2>&1
case $? in
  0)   ;;  # session valide
  124) print -P "%F{yellow}⚠  gcloud injoignable en 2 s — hors ligne ?%f" ;;
  127) ;;  # gtimeout ou gcloud absent : pas d'alerte trompeuse
  *)   print -P "%B%F{red}⚠  gcloud déconnecté → gcloud auth login%f%b" ;;
esac

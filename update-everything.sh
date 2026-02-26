#!/bin/zsh
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

log() { printf "\n[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

# Try to load nvm if available (supports common setups and Homebrew installs)
load_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    return 0
  fi
  if command -v brew >/dev/null 2>&1; then
    local brew_nvm_prefix
    brew_nvm_prefix="$(brew --prefix nvm 2>/dev/null || true)"
    if [ -n "$brew_nvm_prefix" ] && [ -s "$brew_nvm_prefix/nvm.sh" ]; then
      . "$brew_nvm_prefix/nvm.sh"
      return 0
    fi
    # Some setups keep nvm under opt path
    if [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]; then
      . "$(brew --prefix)/opt/nvm/nvm.sh"
      return 0
    fi
  fi
  return 1
}

log "Homebrew: update taps"
brew update

log "Homebrew: upgrade formulae"
brew upgrade

log "Homebrew: upgrade casks (apps like Chrome)"
# --greedy updates casks that auto-update themselves too
brew upgrade --cask --greedy || true

log "Homebrew: cleanup and autoremove"
brew cleanup -s || true
brew autoremove -v || true

log "Node.js: updating nvm and installing latest LTS"
if [ -d "$HOME/.nvm/.git" ]; then
  (cd "$HOME/.nvm" && git fetch --tags origin && git checkout "$(git describe --abbrev=0 --tags --match "v[0-9]*" "$(git rev-list --tags --max-count=1)")") || true
fi

if load_nvm; then
  nvm install --lts --latest-npm || true
  nvm alias default 'lts/*' || true
  log "Node.js: $(node -v 2>/dev/null), npm: $(npm -v 2>/dev/null)"
else
  log "nvm not detected; skipping Node.js updates"
fi

if [[ "${SKIP_MACOS:-}" = "1" ]]; then
  log "Skipping macOS software updates (SKIP_MACOS=1)"
else
  log "macOS: checking & installing software updates (you may be prompted for sudo)"
  if [[ $EUID -ne 0 ]]; then sudo -v; fi
  # Install all available updates; may require restart if necessary
  sudo /usr/sbin/softwareupdate -i -a || true
fi

log "Done."

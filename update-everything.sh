#!/bin/zsh
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

log() { printf "\n[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

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

if [[ "${SKIP_MACOS:-}" = "1" ]]; then
  log "Skipping macOS software updates (SKIP_MACOS=1)"
else
  log "macOS: checking & installing software updates (you may be prompted for sudo)"
  if [[ $EUID -ne 0 ]]; then sudo -v; fi
  # Install all available updates; may require restart if necessary
  sudo /usr/sbin/softwareupdate -i -a || true
fi

log "Done."

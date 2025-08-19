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

if [[ "${SKIP_NODE:-}" = "1" ]]; then
  log "Skipping Node.js toolchain updates (SKIP_NODE=1)"
else
  log "Node.js: updating nvm if installed via Homebrew"
  if command -v brew >/dev/null 2>&1 && brew list nvm >/dev/null 2>&1; then
    brew upgrade nvm || true
  fi

  if load_nvm; then
    log "Node.js: installing latest LTS and updating npm"
    current_node="$(nvm current 2>/dev/null || true)"

    # Optionally capture current global packages for later selective migration
    previous_globals=""
    if [ -n "$current_node" ] && [ "$current_node" != "none" ] && [[ "${MIGRATE_GLOBALS:-}" = "1" ]]; then
      log "Capturing list of current global npm packages for migration"
      previous_globals="$({ npm -g ls --depth=0 --json 2>/dev/null | node -e 'let s=\"\";process.stdin.on(\"data\",d=>s+=d).on(\"end\",()=>{try{let p=JSON.parse(s).dependencies||{};let skip=new Set([\"npm\",\"corepack\"]);for(const n of Object.keys(p)){if(!skip.has(n)) console.log(n)}}catch(e){}}'; } 2>/dev/null || true)"
    fi

    nvm install --lts --latest-npm || true
    nvm alias default 'lts/*' || true

    # Optionally reinstall previous globals one-by-one, skipping failures
    if [ -n "${previous_globals}" ]; then
      log "Reinstalling previous global npm packages (best-effort)"
      for pkg in ${previous_globals}; do
        log "npm -g install ${pkg}"
        npm install -g "$pkg" || log "Skipping failed global reinstall: $pkg"
      done
    fi

    if command -v corepack >/dev/null 2>&1; then
      log "Corepack: enabling and updating Yarn and pnpm"
      corepack enable || true
      corepack prepare yarn@stable --activate || true
      corepack prepare pnpm@latest --activate || true
    else
      log "Corepack not found; attempting to install via npm and retry"
      if command -v npm >/dev/null 2>&1; then
        npm install -g corepack || true
        if command -v corepack >/dev/null 2>&1; then
          corepack enable || true
          corepack prepare yarn@stable --activate || true
          corepack prepare pnpm@latest --activate || true
        fi
      fi
    fi

    log "Node.js: versions"
    node -v 2>/dev/null || true
    npm -v 2>/dev/null || true
    yarn -v 2>/dev/null || true
    pnpm -v 2>/dev/null || true
    corepack --version 2>/dev/null || true
  else
    log "nvm not detected; skipping Node.js/npm/Yarn/pnpm updates"
  fi
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

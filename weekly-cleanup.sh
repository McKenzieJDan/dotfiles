#!/bin/zsh
# Weekly disk cleanup — safe, idempotent. Runs via LaunchAgent io.mckenz.weekly-cleanup.
# Manual run:    ./weekly-cleanup.sh
# Manual launchd trigger: launchctl start io.mckenz.weekly-cleanup
# Log:           ~/Library/Logs/weekly-cleanup.log

set -u
setopt NULL_GLOB  # unmatched globs expand to nothing instead of erroring

LOG="$HOME/Library/Logs/weekly-cleanup.log"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1

echo "===== $(date '+%Y-%m-%d %H:%M:%S') start ====="
BEFORE_KB=$(df -k /System/Volumes/Data | awk 'NR==2 {print $4}')

step() { echo "--- $1 ---"; }

# --- Package manager caches ---
if command -v brew >/dev/null; then
  step "brew cleanup --prune=all"
  brew cleanup --prune=all || echo "(brew cleanup failed)"
fi

if command -v npm >/dev/null; then
  step "npm cache clean --force"
  npm cache clean --force || echo "(npm cache clean failed)"
fi

if command -v go >/dev/null; then
  step "go clean -cache -testcache"
  # NOTE: not clearing -modcache (shared by all Go projects, expensive to rebuild).
  go clean -cache -testcache || echo "(go clean failed)"
fi

# --- Cache dirs that regenerate on demand ---
step "rm app/MCP runtime caches"
rm -rf \
  "$HOME/Library/Caches/restic" \
  "$HOME/.cache/chrome-devtools-mcp" \
  "$HOME/.cache/codex-runtimes" \
  2>/dev/null || true

# --- Stremio streaming cache ---
STREMIO_CACHE="$HOME/Library/Application Support/stremio-server/stremio-cache"
if [ -d "$STREMIO_CACHE" ]; then
  step "rm stremio-cache"
  rm -rf "$STREMIO_CACHE" 2>/dev/null || true
fi

# --- Trash (only items older than 30 days — keep recent deletes recoverable) ---
step "empty Trash (>30 days old)"
find "$HOME/.Trash" -mindepth 1 -maxdepth 1 -mtime +30 -exec rm -rf {} + 2>/dev/null || true

# --- Report ---
AFTER_KB=$(df -k /System/Volumes/Data | awk 'NR==2 {print $4}')
FREED_MB=$(( (AFTER_KB - BEFORE_KB) / 1024 ))
AVAIL_GB=$(( AFTER_KB / 1024 / 1024 ))
echo "Freed ~${FREED_MB} MB. Now ${AVAIL_GB} GB available on data volume."
echo "===== $(date '+%Y-%m-%d %H:%M:%S') done ====="
echo

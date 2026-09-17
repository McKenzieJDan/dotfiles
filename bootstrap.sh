#!/bin/bash
#
# Bootstrap a new Mac. Run with:
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/McKenzieJDan/dotfiles/master/bootstrap.sh)"
#
# Installs Homebrew, clones this repo, then hands off to install.sh.
# Idempotent: re-run anytime to pull the latest config and install again.

set -euo pipefail

REPO_URL="https://github.com/McKenzieJDan/dotfiles.git"
DEST="$HOME/git/dotfiles"

# The Homebrew installer also installs the Xcode Command Line Tools, which
# provide git. Nothing below can run before it.
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
else
  mkdir -p "$(dirname "$DEST")"
  git clone "$REPO_URL" "$DEST"
fi

exec "$DEST/install.sh"

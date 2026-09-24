#!/bin/bash

# Dotfiles Installation Script

# Bash reads a script as it runs, so editing this file (or a git pull) during
# an install makes it resume at the wrong offset. The braces force the whole
# script to be parsed before anything runs.
{
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Mirror everything to a log file, so a stuck or failed run can be inspected
# afterwards (or followed live from another terminal with tail -f).
LOG_FILE="$HOME/Library/Logs/dotfiles-install-$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

START_TIME=$SECONDS

# Section header with elapsed time, so it is obvious which step is running.
step() {
    local elapsed=$((SECONDS - START_TIME))
    echo
    echo -e "${GREEN}==>${NC} $1 ${YELLOW}[$(printf '%02d:%02d' $((elapsed / 60)) $((elapsed % 60))) elapsed]${NC}"
}

trap 'error "Failed at line $LINENO (exit $?). Full log: $LOG_FILE"' ERR

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log "Installing dotfiles from $DOTFILES_DIR"
log "Logging to $LOG_FILE"

step "Homebrew"
if ! command -v brew &> /dev/null; then
    log "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for this session
    if [[ $(uname -m) == 'arm64' ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    log "Homebrew installed and added to PATH"
else
    log "Homebrew already installed"
fi

# Install apps and tools
step "Brewfile ($(grep -cE '^(brew|cask|mas|vscode) ' "$DOTFILES_DIR/Brewfile") packages, this is the slow part)"
cd "$DOTFILES_DIR"
# Homebrew refuses to install from untrusted third-party taps since mid-2026
brew trust garethgeorge/backrest-tap 2>/dev/null || true
brew trust asmvik/formulae 2>/dev/null || true
brew trust stripe/stripe-cli 2>/dev/null || true
# Homebrew downloads casks in parallel and prints nothing until each one
# finishes, so big apps look like a hang. Report the in-flight downloads
# every 10s until brew bundle is done.
download_progress() {
    local cache_dir last_kb=0 kb names count rate
    cache_dir="$(brew --cache)/downloads"
    while sleep 10; do
        shopt -s nullglob
        local partials=("$cache_dir"/*.incomplete)
        shopt -u nullglob
        count=${#partials[@]}
        [ "$count" -eq 0 ] && { last_kb=0; continue; }
        kb=$(du -sk "${partials[@]}" 2>/dev/null | awk '{s+=$1} END {print s+0}')
        names=$(for f in "${partials[@]}"; do f=${f##*--}; echo "${f%%[-_.]*}"; done | paste -sd, - | sed 's/,/, /g')
        # A finished download leaves the total, so only show a rate when it grew.
        rate=""
        [ "$last_kb" -gt 0 ] && [ "$kb" -ge "$last_kb" ] && rate=" at $(( (kb - last_kb) / 10240 )) MB/s"
        echo -e "${YELLOW}  ↓ ${count} downloading, $((kb / 1024)) MB so far${rate}: ${names}${NC}"
        last_kb=$kb
    done
}

download_progress &
PROGRESS_PID=$!
trap 'kill $PROGRESS_PID 2>/dev/null' EXIT

# --verbose prints each package as it finishes. Some casks ask for your
# password via sudo partway through.
brew bundle install --verbose

kill $PROGRESS_PID 2>/dev/null || true
trap - EXIT

step "nvm and Node.js"
if [ ! -d "$HOME/.nvm" ]; then
    log "Installing nvm (Node Version Manager)..."
    # PROFILE=/dev/null stops the installer editing shell profiles; .zshrc loads nvm itself
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | PROFILE=/dev/null bash
    
    # Load nvm for this session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install latest LTS version of Node.js
    log "Installing latest LTS version of Node.js via nvm..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    
    log "✅ nvm installed with Node.js $(node --version)"
else
    log "nvm already installed"
fi

# Backup existing dotfiles
# The backup directory is created on first use, so a clean machine gets none.
backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

backup() {
    mkdir -p "$backup_dir"
    mv "$1" "$backup_dir/$2"
    log "Backed up $2 to $backup_dir/"
}

step "Dotfiles"
log "Backing up existing dotfiles..."
for dotfile in .zshrc .gitconfig .gitignore_global; do
    if [ -f "$HOME/$dotfile" ] && [ ! -L "$HOME/$dotfile" ]; then
        backup "$HOME/$dotfile" "$dotfile"
    fi
done

# Create main dotfile symlinks
log "Creating main dotfile symlinks..."

if [ -f "$DOTFILES_DIR/.config/zsh/.zshrc" ]; then
    ln -sf "$DOTFILES_DIR/.config/zsh/.zshrc" "$HOME/.zshrc"
    log "Linked .zshrc → .config/zsh/.zshrc"
else
    warn ".config/zsh/.zshrc not found, skipping"
fi

if [ -f "$DOTFILES_DIR/.config/git/.gitconfig" ]; then
    ln -sf "$DOTFILES_DIR/.config/git/.gitconfig" "$HOME/.gitconfig"
    log "Linked .gitconfig → .config/git/.gitconfig"
else
    warn ".config/git/.gitconfig not found, skipping"
fi

if [ -f "$DOTFILES_DIR/.config/git/.gitignore_global" ]; then
    ln -sf "$DOTFILES_DIR/.config/git/.gitignore_global" "$HOME/.gitignore_global"
    log "Linked .gitignore_global → .config/git/.gitignore_global"
else
    warn ".config/git/.gitignore_global not found, skipping"
fi

# Create .config directory and symlink config directories
log "Setting up .config directory..."
mkdir -p "$HOME/.config"

# Link entire config directories
for config_dir in "$DOTFILES_DIR/.config"/*; do
    if [ -d "$config_dir" ]; then
        config_name=$(basename "$config_dir")
        target="$HOME/.config/$config_name"
        
        # A symlink is ours to replace. Anything real belongs to the user,
        # so move it to the backup directory instead of deleting it.
        if [ -L "$target" ]; then
            rm -f "$target"
        elif [ -e "$target" ]; then
            backup "$target" "config_$config_name"
        fi
        
        ln -sf "$config_dir" "$target"
        log "Linked .config/$config_name → dotfiles/.config/$config_name"
    fi
done

# VS Code reads its config from Application Support, not ~/.config
vscode_user="$HOME/Library/Application Support/Code/User"
mkdir -p "$vscode_user"
for vscode_file in settings.json keybindings.json; do
    target="$vscode_user/$vscode_file"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        backup "$target" "vscode_$vscode_file"
    fi
    ln -sf "$DOTFILES_DIR/.config/vscode/$vscode_file" "$target"
    log "Linked VS Code $vscode_file → .config/vscode/$vscode_file"
done

step "Scripts and LaunchAgents"
log "Making scripts executable..."
chmod +x "$DOTFILES_DIR/macos-setup.sh"
chmod +x "$DOTFILES_DIR/update-everything.sh"
chmod +x "$DOTFILES_DIR/cleanup.sh"
chmod +x "$DOTFILES_DIR/weekly-cleanup.sh"

# Install weekly-cleanup LaunchAgent (Sundays 03:15)
log "Installing weekly-cleanup LaunchAgent..."
LA_TEMPLATE="$DOTFILES_DIR/launchagents/io.mckenz.weekly-cleanup.plist.template"
LA_TARGET="$HOME/Library/LaunchAgents/io.mckenz.weekly-cleanup.plist"
if [ -f "$LA_TEMPLATE" ]; then
    mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
    sed -e "s|__DOTFILES_DIR__|$DOTFILES_DIR|g" \
        -e "s|__HOME__|$HOME|g" \
        "$LA_TEMPLATE" > "$LA_TARGET"
    launchctl unload "$LA_TARGET" 2>/dev/null || true
    if launchctl load -w "$LA_TARGET" 2>/dev/null; then
        log "✅ weekly-cleanup scheduled (Sundays 03:15). Log: ~/Library/Logs/weekly-cleanup.log"
    else
        warn "weekly-cleanup plist installed but launchctl load failed — try manually"
    fi
else
    warn "weekly-cleanup template not found, skipping"
fi

# Make config scripts executable if they exist
if [ -f "$DOTFILES_DIR/.config/yabai/yabairc" ]; then
    chmod +x "$DOTFILES_DIR/.config/yabai/yabairc"
fi

step "macOS preferences"
read -p "Do you want to run macOS system preferences setup? (y/N): " -n 1 -r || true
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Running macOS setup..."
    "$DOTFILES_DIR/macos-setup.sh"
else
    warn "Skipping macOS setup. You can run it later with: ./macos-setup.sh"
fi

step "Services"
if command -v yabai &> /dev/null && command -v skhd &> /dev/null; then
    log "Starting yabai and skhd services..."
    if yabai --start-service 2>/dev/null && skhd --start-service 2>/dev/null; then
        log "✅ Window management services started"
    else
        warn "Failed to start yabai/skhd. You may need to grant accessibility permissions in System Settings > Privacy & Security > Accessibility"
        warn "Then run: yabai --start-service && skhd --start-service"
    fi
fi

# Setup backrest configuration
if [ -f "$HOME/.config/backrest/config.json.template" ] && [ ! -f "$HOME/.config/backrest/config.json" ]; then
    warn "Backrest config template found but no config.json exists."
    warn "Please copy and configure: cp ~/.config/backrest/config.json.template ~/.config/backrest/config.json"
    warn "See ~/.config/backrest/README.md for setup instructions."
fi

# Start backrest service
if command -v backrest &> /dev/null && [ -f "$HOME/.config/backrest/config.json" ]; then
    log "Starting backrest service..."
    brew services start garethgeorge/backrest-tap/backrest
elif command -v backrest &> /dev/null; then
    warn "Backrest installed but config.json not found. Service not started."
fi

log "Installation complete in $(((SECONDS - START_TIME) / 60))m $(((SECONDS - START_TIME) % 60))s. Log: $LOG_FILE"
echo
echo "Next steps:"
echo "1. Restart your terminal or run 'source ~/.zshrc'"
echo "2. Run macOS setup if you haven't already: ./macos-setup.sh"
echo "3. Review and customize configurations as needed"
echo
log "Don't forget to restart your system to apply all macOS changes!"
exit
}

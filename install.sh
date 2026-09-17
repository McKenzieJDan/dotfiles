#!/bin/bash

# Dotfiles Installation Script
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

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log "Installing dotfiles from $DOTFILES_DIR"

# Install Homebrew if not present
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
log "Installing applications and tools via Homebrew..."
cd "$DOTFILES_DIR"
# Homebrew refuses to install from untrusted third-party taps since mid-2026
brew trust garethgeorge/backrest-tap 2>/dev/null || true
brew trust asmvik/formulae 2>/dev/null || true
brew trust stripe/stripe-cli 2>/dev/null || true
brew bundle install

# Install nvm (Node Version Manager)
if [ ! -d "$HOME/.nvm" ]; then
    log "Installing nvm (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    
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

# Make scripts executable
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

# Run macOS setup
read -p "Do you want to run macOS system preferences setup? (y/N): " -n 1 -r || true
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Running macOS setup..."
    "$DOTFILES_DIR/macos-setup.sh"
else
    warn "Skipping macOS setup. You can run it later with: ./macos-setup.sh"
fi

# Start yabai and skhd services
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

log "Installation complete!"
echo
echo "Next steps:"
echo "1. Restart your terminal or run 'source ~/.zshrc'"
echo "2. Run macOS setup if you haven't already: ./macos-setup.sh"
echo "3. Review and customize configurations as needed"
echo
log "Don't forget to restart your system to apply all macOS changes!"

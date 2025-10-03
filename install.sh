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
brew bundle install

# Backup existing dotfiles
log "Backing up existing dotfiles..."
backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
backup_needed=false

# Check if backup is needed for individual dotfiles
for dotfile in .zshrc .gitconfig .gitignore_global; do
    if [ -f "$HOME/$dotfile" ] && [ ! -L "$HOME/$dotfile" ]; then
        backup_needed=true
        break
    fi
done

# Check if backup is needed for config directories
if [ "$backup_needed" = false ]; then
    for config in git zsh backrest yabai skhd; do
        if [ -d "$HOME/.config/$config" ] && [ ! -L "$HOME/.config/$config" ]; then
            backup_needed=true
            break
        fi
    done
fi

# Only create backup directory if needed
if [ "$backup_needed" = true ]; then
    mkdir -p "$backup_dir"
    
    # Backup individual dotfiles in home directory
    for dotfile in .zshrc .gitconfig .gitignore_global; do
        if [ -f "$HOME/$dotfile" ] && [ ! -L "$HOME/$dotfile" ]; then
            mv "$HOME/$dotfile" "$backup_dir/"
            log "Backed up $dotfile to $backup_dir/"
        fi
    done
    
    # Backup existing config directories
    for config in git zsh backrest yabai skhd; do
        if [ -d "$HOME/.config/$config" ] && [ ! -L "$HOME/.config/$config" ]; then
            mv "$HOME/.config/$config" "$backup_dir/config_$config" 2>/dev/null || true
            log "Backed up .config/$config to $backup_dir/config_$config"
        fi
    done
else
    log "No existing dotfiles to backup"
fi

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
        ln -sf "$config_dir" "$HOME/.config/$config_name"
        log "Linked .config/$config_name → dotfiles/.config/$config_name"
    fi
done

# Make scripts executable
log "Making scripts executable..."
chmod +x "$DOTFILES_DIR/macos-setup.sh"
chmod +x "$DOTFILES_DIR/update-everything.sh"

# Make config scripts executable if they exist
if [ -f "$DOTFILES_DIR/.config/yabai/yabairc" ]; then
    chmod +x "$DOTFILES_DIR/.config/yabai/yabairc"
fi

# Setup GPG agent for commit signing
if command -v gpg &> /dev/null && command -v pinentry-mac &> /dev/null; then
    read -p "Do you want to configure GPG commit signing with passphrase caching? (y/N): " -n 1 -r || true
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Configuring GPG agent with pinentry-mac..."
        mkdir -p "$HOME/.gnupg"
        chmod 700 "$HOME/.gnupg"
        
        # Create or update gpg-agent.conf
        PINENTRY_PATH=$(which pinentry-mac 2>/dev/null || echo "/opt/homebrew/bin/pinentry-mac")
        cat > "$HOME/.gnupg/gpg-agent.conf" << EOF
# Use macOS pinentry for passphrase prompts
pinentry-program $PINENTRY_PATH

# Cache passphrase for 1 hour (3600 seconds)
default-cache-ttl 3600

# Maximum cache time of 2 hours (7200 seconds)
max-cache-ttl 7200
EOF
        
        log "GPG agent configured. Restarting gpg-agent..."
        killall gpg-agent 2>/dev/null || true
        gpgconf --launch gpg-agent
        
        log "✅ GPG setup complete! On first commit, tick 'Save in Keychain' to remember passphrase."
    else
        warn "Skipping GPG setup. You can configure it later by editing ~/.gnupg/gpg-agent.conf"
    fi
else
    warn "GPG or pinentry-mac not found. Skipping GPG agent setup."
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

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
mkdir -p "$backup_dir"

# Backup existing dotfiles and configs
if [ -f "$HOME/.zshrc" ]; then
    mv "$HOME/.zshrc" "$backup_dir/"
    log "Backed up .zshrc to $backup_dir/"
fi

# Backup existing config directories
for config in git zsh backrest; do
    if [ -d "$HOME/.config/$config" ]; then
        mv "$HOME/.config/$config" "$backup_dir/config_$config" 2>/dev/null || true
        log "Backed up .config/$config to $backup_dir/config_$config"
    fi
done

# Backup .config directory if it exists
if [ -d "$HOME/.config" ]; then
    cp -r "$HOME/.config" "$backup_dir/" 2>/dev/null || true
    log "Backed up .config directory to $backup_dir/ (ignoring socket files and permission errors)"
fi

# Create main dotfile symlinks
log "Creating main dotfile symlinks..."
ln -sf "$DOTFILES_DIR/.config/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/.config/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES_DIR/.config/git/.gitignore_global" "$HOME/.gitignore_global"
log "Linked .zshrc → .config/zsh/.zshrc"
log "Linked .gitconfig → .config/git/.gitconfig"
log "Linked .gitignore_global → .config/git/.gitignore_global"

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
    log "Configuring GPG agent with pinentry-mac..."
    mkdir -p "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"
    
    # Create or update gpg-agent.conf
    cat > "$HOME/.gnupg/gpg-agent.conf" << EOF
# Use macOS pinentry for passphrase prompts
pinentry-program $(which pinentry-mac)

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
    warn "GPG or pinentry-mac not found. Skipping GPG agent setup."
fi

# Run macOS setup
read -p "Do you want to run macOS system preferences setup? (y/N): " -n 1 -r
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
    yabai --start-service
    skhd --start-service
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
echo "2. Update your Git user info in ~/.gitconfig"
echo "3. Update computer name and login banner in the setup script"
echo "4. Review and customize configurations as needed"
echo
log "Don't forget to restart your system to apply all macOS changes!"

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

# Backup individual dotfiles
for file in .zshrc .aliases .functions .gitconfig .gitignore_global; do
    if [ -f "$HOME/$file" ]; then
        mv "$HOME/$file" "$backup_dir/"
        log "Backed up $file to $backup_dir/"
    fi
done

# Backup .config directory if it exists
if [ -d "$HOME/.config" ]; then
    cp -r "$HOME/.config" "$backup_dir/" 2>/dev/null || true
    log "Backed up .config directory to $backup_dir/ (ignoring socket files and permission errors)"
fi

# Create symlinks for dotfiles
log "Creating symlinks for dotfiles..."
for file in .zshrc .aliases .functions .gitconfig .gitignore_global; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
        ln -sf "$DOTFILES_DIR/$file" "$HOME/$file"
        log "Linked $file"
    fi
done

# Create .config directory and symlink individual config files
log "Setting up .config directory..."
mkdir -p "$HOME/.config"

if [ -d "$DOTFILES_DIR/.config" ]; then
    for config_dir in "$DOTFILES_DIR/.config"/*; do
        if [ -d "$config_dir" ]; then
            config_name=$(basename "$config_dir")
            mkdir -p "$HOME/.config/$config_name"
            
            # Link individual files instead of the whole directory
            for config_file in "$config_dir"/*; do
                if [ -f "$config_file" ]; then
                    file_name=$(basename "$config_file")
                    ln -sf "$config_file" "$HOME/.config/$config_name/$file_name"
                    log "Linked .config/$config_name/$file_name"
                fi
            done
        fi
    done
fi

# Make scripts executable
log "Making scripts executable..."
chmod +x "$DOTFILES_DIR/macos-setup.sh"
chmod +x "$DOTFILES_DIR/update-everything.sh"

# Make config scripts executable if they exist
if [ -f "$DOTFILES_DIR/.config/yabai/yabairc" ]; then
    chmod +x "$DOTFILES_DIR/.config/yabai/yabairc"
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

log "Installation complete!"
echo
echo "Next steps:"
echo "1. Restart your terminal or run 'source ~/.zshrc'"
echo "2. Update your Git user info in ~/.gitconfig"
echo "3. Update computer name and login banner in the setup script"
echo "4. Review and customize configurations as needed"
echo
log "Don't forget to restart your system to apply all macOS changes!"

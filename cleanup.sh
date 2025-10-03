#!/bin/bash
# Cleanup Script
# Frees up disk space by clearing caches and temporary files

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

info() {
    echo -e "${BLUE}[CLEAN]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Get disk space before cleanup
get_disk_space() {
    df -h / | awk 'NR==2 {print $4}'
}

SPACE_BEFORE=$(get_disk_space)

echo "🧹 Starting cleanup..."
echo "Available space before cleanup: $SPACE_BEFORE"
echo ""

# Homebrew cleanup
if command -v brew &> /dev/null; then
    log "Cleaning Homebrew caches..."
    
    info "Removing old versions of installed formulae"
    brew cleanup -s || true
    
    info "Removing unused dependencies"
    brew autoremove -v || true
    
    info "Clearing Homebrew cache directory"
    rm -rf "$(brew --cache)" 2>/dev/null || true
    
    info "Clearing downloads cache"
    rm -rf ~/Library/Caches/Homebrew/* 2>/dev/null || true
else
    warn "Homebrew not found, skipping"
fi

# Node.js cleanup
if command -v npm &> /dev/null; then
    log "Cleaning Node.js caches..."
    
    info "Clearing npm cache"
    npm cache clean --force 2>/dev/null || true
    
    info "Clearing npm temporary files"
    rm -rf ~/.npm/_cacache 2>/dev/null || true
    rm -rf ~/.npm/_logs 2>/dev/null || true
else
    warn "npm not found, skipping"
fi

if command -v yarn &> /dev/null; then
    info "Clearing Yarn cache"
    yarn cache clean 2>/dev/null || true
    rm -rf ~/Library/Caches/Yarn 2>/dev/null || true
fi

if command -v pnpm &> /dev/null; then
    info "Clearing pnpm cache"
    pnpm store prune 2>/dev/null || true
fi

# nvm cleanup
if [ -d "$HOME/.nvm" ]; then
    log "Cleaning nvm caches..."
    
    info "Clearing nvm cache"
    rm -rf ~/.nvm/.cache 2>/dev/null || true
    
    info "Removing old nvm versions (keeping current version)"
    # This will only clean up if nvm is loaded
    if command -v nvm &> /dev/null; then
        nvm cache clear 2>/dev/null || true
    fi
fi

# Python cleanup
if command -v pip3 &> /dev/null; then
    log "Cleaning Python caches..."
    
    info "Clearing pip cache"
    pip3 cache purge 2>/dev/null || true
    
    info "Removing __pycache__ directories"
    find ~ -type d -name "__pycache__" -depth -exec rm -rf {} \; 2>/dev/null || true
    find ~ -type f -name "*.pyc" -delete 2>/dev/null || true
fi

# Rust cleanup
if command -v cargo &> /dev/null; then
    log "Cleaning Rust caches..."
    
    info "Clearing Cargo cache"
    cargo cache -a 2>/dev/null || true
fi

# Go cleanup
if command -v go &> /dev/null; then
    log "Cleaning Go caches..."
    
    info "Clearing Go build cache"
    go clean -cache 2>/dev/null || true
    go clean -modcache 2>/dev/null || true
fi

# macOS system cleanup
log "Cleaning macOS system caches..."

info "Clearing user cache files"
rm -rf ~/Library/Caches/* 2>/dev/null || true

info "Clearing system logs"
rm -rf ~/Library/Logs/* 2>/dev/null || true

info "Emptying trash (may require permissions)"
rm -rf ~/.Trash/* 2>/dev/null || true

info "Clearing Downloads folder .DS_Store files"
find ~/Downloads -name ".DS_Store" -delete 2>/dev/null || true

info "Clearing Safari cache (if not running)"
if ! pgrep -x "Safari" > /dev/null; then
    rm -rf ~/Library/Caches/com.apple.Safari/* 2>/dev/null || true
    rm -rf ~/Library/Safari/LocalStorage/* 2>/dev/null || true
else
    warn "Safari is running, skipping Safari cache cleanup"
fi

# Development cleanup
log "Cleaning development artifacts..."

info "Removing .DS_Store files from home directory"
find ~ -name ".DS_Store" -type f -delete 2>/dev/null || true

info "Clearing Xcode derived data"
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true

info "Clearing Xcode archives (keep if you need them!)"
# Commented out by default - uncomment if you want to remove old archives
# rm -rf ~/Library/Developer/Xcode/Archives/* 2>/dev/null || true

info "Clearing iOS device support files (old versions)"
find ~/Library/Developer/Xcode/iOS\ DeviceSupport/ -mindepth 1 -maxdepth 1 -mtime +30 -exec rm -rf {} \; 2>/dev/null || true

# Docker cleanup (if installed)
if command -v docker &> /dev/null; then
    log "Cleaning Docker..."
    
    read -p "Clean Docker images, containers, and volumes? This will remove stopped containers. (y/N): " -n 1 -r || true
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Removing stopped containers"
        docker container prune -f 2>/dev/null || true
        
        info "Removing unused images"
        docker image prune -a -f 2>/dev/null || true
        
        info "Removing unused volumes"
        docker volume prune -f 2>/dev/null || true
        
        info "Removing unused networks"
        docker network prune -f 2>/dev/null || true
    else
        warn "Skipping Docker cleanup"
    fi
fi

# Old backups cleanup
log "Checking for old dotfile backups..."

BACKUP_COUNT=$(find ~ -maxdepth 1 -name ".dotfiles_backup_*" -type d 2>/dev/null | wc -l | tr -d ' ')
if [ "$BACKUP_COUNT" -gt 0 ]; then
    echo "Found $BACKUP_COUNT dotfiles backup directories"
    ls -dt ~/.dotfiles_backup_* 2>/dev/null | head -5
    echo ""
    read -p "Keep the 2 most recent backups and delete the rest? (y/N): " -n 1 -r || true
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Keeping 2 most recent backups, removing older ones"
        ls -dt ~/.dotfiles_backup_* 2>/dev/null | tail -n +3 | xargs rm -rf 2>/dev/null || true
    else
        warn "Skipping backup cleanup"
    fi
fi

# Get disk space after cleanup
SPACE_AFTER=$(get_disk_space)

echo ""
echo "✅ Cleanup complete!"
echo "Available space before: $SPACE_BEFORE"
echo "Available space after:  $SPACE_AFTER"
echo ""
echo "💡 Tip: Run 'update-everything' to keep your system up to date!"


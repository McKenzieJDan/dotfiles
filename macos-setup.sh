#!/bin/bash
# macOS Setup Script
# Run this after setting up a new Mac to apply preferred system settings

# Exit on error, but allow some commands to fail gracefully
set -e

echo "Setting up macOS preferences..."

# Dock Settings
echo "Configuring Dock..."

# Remove dock autohide delay
defaults write com.apple.dock autohide-delay -float 0

# Speed up dock autohide animation (0.15 seconds)
defaults write com.apple.dock autohide-time-modifier -float 0.15

# Alternative: Instant dock hide (uncomment if preferred)
# defaults write com.apple.dock autohide-time-modifier -int 0

# Show only active applications in Dock
defaults write com.apple.Dock static-only -bool TRUE

# Finder Settings
echo "Configuring Finder..."

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool false

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool false

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Remove the spring loading delay for directories
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use icon view in all Finder windows by default
# Four-letter codes for the other view modes: `Nlsv` (list), `clmv` (column), `glyv` (gallery)
defaults write com.apple.finder FXPreferredViewStyle -string "glyv"

# Icon view settings
defaults write com.apple.finder IconViewSettings -dict-add arrangeBy name
defaults write com.apple.finder IconViewSettings -dict-add gridSpacing 54
defaults write com.apple.finder IconViewSettings -dict-add iconSize 64
defaults write com.apple.finder IconViewSettings -dict-add showItemInfo false
defaults write com.apple.finder IconViewSettings -dict-add textSize 12

# Desktop icon view settings
defaults write com.apple.finder DesktopViewSettings -dict-add arrangeBy name
defaults write com.apple.finder DesktopViewSettings -dict-add gridSpacing 54
defaults write com.apple.finder DesktopViewSettings -dict-add iconSize 64
defaults write com.apple.finder DesktopViewSettings -dict-add showItemInfo false
defaults write com.apple.finder DesktopViewSettings -dict-add textSize 12

# Snap to grid for icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy name" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy name" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy name" ~/Library/Preferences/com.apple.finder.plist 2>/dev/null || true

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Trackpad & Mouse Settings
echo "Configuring trackpad and mouse..."

# Set trackpad tracking speed (0-3 scale, where 2 is moderately fast)
defaults write -g com.apple.trackpad.scaling -int 2

# Set mouse tracking speed (0-3 scale, uncomment if you use a mouse)
# defaults write -g com.apple.mouse.scaling -int 2

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: map bottom right corner to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Enable "natural" (Lion-style) scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Keyboard Settings
echo "Configuring keyboard..."

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Screen Settings
echo "Configuring screen settings..."

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Desktop"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Enable HiDPI display modes (requires restart)
if sudo -v 2>/dev/null; then
    sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
else
    echo "⚠️  Skipping HiDPI setup - requires admin privileges"
fi

# Hot Corners
echo "Configuring hot corners..."

# Top left screen corner → Lock Screen
defaults write com.apple.dock wvous-tl-corner -int 13
defaults write com.apple.dock wvous-tl-modifier -int 0

# Restart Dock to apply all Dock settings
killall Dock || true

# Set Computer Name
echo ""
echo "Setting computer name..."
CURRENT_NAME=$(scutil --get ComputerName 2>/dev/null || echo "")

if [ -n "$CURRENT_NAME" ]; then
    echo "Current computer name: $CURRENT_NAME"
    read -p "Do you want to change the computer name? (y/N): " -n 1 -r || true
    echo
    CHANGE_NAME=$REPLY
else
    CHANGE_NAME="y"
fi

if [[ $CHANGE_NAME =~ ^[Yy]$ ]]; then
    echo "💡 Suggestion: Use Greek/space names (e.g., Apollo, Artemis, Satellite, Rocket, Cosmos, Orion)"
    read -p "Enter new computer name: " NEW_NAME || true
    
    if [ -n "$NEW_NAME" ]; then
        if sudo -v 2>/dev/null; then
            sudo scutil --set ComputerName "$NEW_NAME"
            sudo scutil --set HostName "$NEW_NAME"
            sudo scutil --set LocalHostName "$NEW_NAME"
            echo "✅ Computer name set to: $NEW_NAME"
        else
            echo "⚠️  Could not set computer name - requires admin privileges"
        fi
    else
        echo "⚠️  No name entered, skipping"
    fi
else
    echo "Keeping current computer name: $CURRENT_NAME"
fi

# Login Window Banner
echo ""
echo "Setting up login window banner..."
CURRENT_BANNER=$(sudo defaults read /Library/Preferences/com.apple.loginwindow LoginwindowText 2>/dev/null || echo "")

if [ -n "$CURRENT_BANNER" ]; then
    echo "Current login banner: $CURRENT_BANNER"
    read -p "Do you want to change the login banner? (y/N): " -n 1 -r || true
    echo
    CHANGE_BANNER=$REPLY
else
    CHANGE_BANNER="y"
fi

if [[ $CHANGE_BANNER =~ ^[Yy]$ ]]; then
    echo "Enter your information for the login banner:"
    read -p "First name: " FIRST_NAME || true
    read -p "Last name: " LAST_NAME || true
    read -p "Email: " EMAIL || true
    read -p "Phone number: " PHONE || true
    
    if [ -n "$FIRST_NAME" ] && [ -n "$LAST_NAME" ]; then
        BANNER_TEXT="This Mac belongs to $FIRST_NAME $LAST_NAME."
        
        if [ -n "$EMAIL" ] && [ -n "$PHONE" ]; then
            BANNER_TEXT="$BANNER_TEXT If found, email $EMAIL or call $PHONE."
        elif [ -n "$EMAIL" ]; then
            BANNER_TEXT="$BANNER_TEXT If found, email $EMAIL."
        elif [ -n "$PHONE" ]; then
            BANNER_TEXT="$BANNER_TEXT If found, call $PHONE."
        fi
        
        if sudo -v 2>/dev/null; then
            sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$BANNER_TEXT"
            echo "✅ Login banner set to: $BANNER_TEXT"
        else
            echo "⚠️  Could not set login banner - requires admin privileges"
        fi
    else
        echo "⚠️  First name and last name are required, skipping login banner setup"
    fi
else
    echo "Keeping current login banner"
fi

# Make update script executable
echo ""
echo "Setting up update script..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/update-everything.sh" ]; then
    chmod +x "$SCRIPT_DIR/update-everything.sh"
    echo "✅ update-everything.sh is executable"
    echo "   Access via alias: update-everything (configured in .zsh/.aliases)"
else
    echo "⚠️  update-everything.sh not found"
fi

# Restart affected applications
echo "Restarting affected applications..."
for app in "Dock" \
	"Finder" \
	"Google Chrome" \
	"SystemUIServer" \
	"cfprefsd"; do
	killall "${app}" &> /dev/null || true
done

echo ""
echo "✅ macOS setup complete!"
echo ""
echo "Next steps:"
echo "- Run system updates: update-everything"
echo "- Restart your Mac to apply all changes"

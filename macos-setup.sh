#!/bin/bash
# macOS Setup Script
# Run this after setting up a new Mac to apply preferred system settings

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

# Restart Dock to apply changes
killall Dock

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

# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Trackpad & Mouse Settings
echo "Configuring trackpad and mouse..."

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: map bottom right corner to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

# Disable "natural" (Lion-style) scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

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
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

# Hot Corners
echo "Configuring hot corners..."

# Top left screen corner → Lock Screen
defaults write com.apple.dock wvous-tl-corner -int 13
defaults write com.apple.dock wvous-tl-modifier -int 0

# Set Computer Name
echo "Setting computer name..."
echo "💡 Suggestion: Use Greek/space names (e.g., Apollo, Artemis, Satellite, Rocket, Cosmos, Orion)"

# TODO: Replace with your chosen name (uncomment and edit)
# sudo scutil --set ComputerName "YourMacName"
# sudo scutil --set HostName "YourMacName"
# sudo scutil --set LocalHostName "YourMacName"
echo "Skipping computer name setup - edit script to customize"

# Login Window Banner
echo "Setting up login window banner..."
echo "⚠️  CUSTOMIZE THE DETAILS BELOW:"

# TODO: Replace with your actual info (uncomment and edit)
# sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "This Mac belongs to Your Name. Call 555-1234 if found."
echo "Skipping login banner setup - edit script to customize"

# Make update script globally accessible
echo "Setting up global update script..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "$SCRIPT_DIR/update-everything.sh"
sudo ln -sf "$SCRIPT_DIR/update-everything.sh" /usr/local/bin/update-everything
echo "✅ update-everything script installed globally"

# Restart affected applications
echo "Restarting affected applications..."
for app in "Dock" \
	"Finder" \
	"Google Chrome" \
	"SystemUIServer" \
	"cfprefsd"; do
	killall "${app}" &> /dev/null || true
done

echo "macOS setup complete!"
echo ""
echo "Additional manual setup:"
echo "- Configure Git: update name/email in ~/.gitconfig"
echo "- Edit this script to set computer name and login banner"
echo "- Run system updates: update-everything"
echo "- Some changes require a logout/restart to take effect"

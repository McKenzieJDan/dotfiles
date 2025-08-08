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

# Set Computer Name
echo "Setting computer name..."
echo "💡 Suggestion: Use Greek/space names (e.g., Apollo, Artemis, Satellite, Rocket, Cosmos, Orion)"

# TODO: Replace [COMPUTER_NAME] with your chosen name
sudo scutil --set ComputerName "[COMPUTER_NAME]"
sudo scutil --set HostName "[COMPUTER_NAME]"
sudo scutil --set LocalHostName "[COMPUTER_NAME]"

# Login Window Banner
echo "Setting up login window banner..."
echo "⚠️  CUSTOMIZE THE DETAILS BELOW:"

# TODO: Replace with your actual name and contact info
loginbanner=$(printf "This Mac belongs to [YOUR NAME].\nCall [YOUR PHONE] if found.")
sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$loginbanner"

echo "macOS setup complete!"
echo ""
echo "Additional manual setup:"
echo "- Install apps: brew bundle install"
echo "- Copy configs: cp -r .config/* ~/.config/"
echo "- Copy dotfiles: cp .skhdrc .yabairc .gitconfig ~/"

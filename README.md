hi# My Dotfiles

Personal macOS setup. Quick install for new machines.

## What's Here

- **Apps**: Brewfile with all the tools I use
- **macOS tweaks**: Dock hide improvements, Finder settings, fast keyboard repeat
- **Shell**: zsh with good aliases and functions  
- **Window management**: yabai + skhd configs
- **Git**: Decent defaults and shortcuts
- **Backup**: Backrest configuration template (requires setup)

## Setup

```bash
./install.sh
```

That's it. Installs everything and sets up symlinks.

## Key Bindings

Window management (Cmd + Alt + Ctrl + ...):
- `F`: Toggle fullscreen
- `S`: Toggle floating  
- `Arrow Keys`: Focus windows
- `Shift + Arrow Keys`: Move windows
- `Shift + 1-9`: Move to space

## Notes

- Update Git name/email in `~/.gitconfig`
- Update computer name in `macos-setup.sh`
- Configure Backrest: see `.config/backrest/README.md`

## Files

```
Brewfile                    # Homebrew package list
install.sh                  # Auto-setup script
macos-setup.sh             # System preferences
update-everything.sh       # Update script
.config/
  ├── git/                 # Git configuration
  ├── zsh/                 # Shell configuration  
  ├── yabai/               # Window manager
  ├── skhd/                # Hotkey daemon
  ├── karabiner/           # Keyboard remapping
  └── backrest/            # Backup configuration
```

## Maintenance

```bash
update-everything
```

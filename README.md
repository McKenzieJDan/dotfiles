hi# My Dotfiles

Personal macOS setup. Quick install for new machines.

## What's Here

- **Apps**: Brewfile with all the tools I use
- **macOS tweaks**: Dock hide improvements, Finder settings, fast keyboard repeat
- **Shell**: zsh with good aliases and functions  
- **Window management**: yabai + skhd configs
- **Git**: Decent defaults and shortcuts
- **Backup**: Backrest configuration template (requires setup)
- **Weekly cleanup**: LaunchAgent that runs `weekly-cleanup.sh` Sundays 03:15

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
cleanup.sh                 # Manual interactive cleanup
weekly-cleanup.sh          # Automated cleanup (run by LaunchAgent)
launchagents/              # LaunchAgent plist templates
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

## Weekly cleanup

`install.sh` registers a LaunchAgent that runs `weekly-cleanup.sh` every Sunday at 03:15 (or next wake if asleep). Clears brew/npm/go caches, MCP runtime caches, stremio cache, restic cache, and Trash items older than 30 days. Logs to `~/Library/Logs/weekly-cleanup.log`.

```bash
./weekly-cleanup.sh                              # run now
launchctl start io.mckenz.weekly-cleanup         # trigger via launchd
tail -50 ~/Library/Logs/weekly-cleanup.log       # check log
launchctl unload ~/Library/LaunchAgents/io.mckenz.weekly-cleanup.plist  # disable
```

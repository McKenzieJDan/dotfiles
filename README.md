# My Dotfiles

Personal macOS setup. Quick install for new machines.

## What's Here

- **Apps**: Brewfile with all the tools I use
- **macOS tweaks**: Dock hide improvements, Finder settings, fast keyboard repeat
- **Shell**: zsh with good aliases and functions  
- **Window management**: yabai + skhd configs
- **Git**: Decent defaults and shortcuts

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

- Update Git name/email in `.gitconfig`
- Update computer name in `macos-setup.sh`

## Files

```
Brewfile            
install.sh           
macos-setup.sh       
update-everything    
.zshrc              
.config/yabai/      
.config/skhd/       
```

## Maintenance

```bash
update-everything
```

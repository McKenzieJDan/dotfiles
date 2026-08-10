# Backrest setup

Backrest (web UI + orchestrator for restic) runs as a Homebrew service and backs up the home directory daily to Backblaze B2.

## Fresh machine setup

1. `brew trust garethgeorge/backrest-tap` (untrusted-tap requirement since mid-2026; install.sh does this)
2. `cp config.json.template config.json` and fill in the placeholders.
   Real credentials live in 1Password (search "Restic") - repo URL, repo password, B2 keys, restore instructions.
3. `brew services start garethgeorge/backrest-tap/backrest`
4. UI at http://localhost:9898

## Notes

- `config.json` contains secrets and is gitignored - only the template is tracked.
- After editing config.json by hand, restart backrest: `launchctl kickstart -k gui/501/homebrew.mxcl.backrest`.
  **Never restart while restic is running** - check `pgrep -f backrest/restic` first. Killing a forget/prune leaves a stale repo lock that silently breaks retention until `restic unlock`.
- `--exclude-cloud-files` (restic >= 0.19) skips iCloud-evicted placeholder files instead of erroring. This means iCloud-only files are NOT in the backup.
- The bundled restic binary lives at `~/.local/share/backrest/restic`.

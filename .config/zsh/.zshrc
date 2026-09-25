# Environment variables
export EDITOR='code --wait'
export BROWSER='safari'
export LANG=en_US.UTF-8

# Java
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"

# Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_INSECURE_REDIRECT=1

# Node.js
export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.npm-global/bin:$PATH"
nvm() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm "$@"; }
node() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; node "$@"; }
npm() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; npm "$@"; }
npx() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; npx "$@"; }

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Go
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Rust (Homebrew rustup is keg-only)
export PATH="/opt/homebrew/opt/rustup/bin:$HOME/.cargo/bin:$PATH"

# Python
export PATH="$HOME/.local/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null && eval "$(pyenv init - --no-rehash)"

# GPG
if command -v gpgconf >/dev/null 2>&1; then
  export GPG_TTY=$(tty)
fi

# FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
# Keybindings: ctrl+t insert file path, alt+c cd into dir
# (Atuin replaces fzf's ctrl+r further down)
command -v fzf >/dev/null && source <(fzf --zsh)

# Source additional zsh config files
source ~/.config/zsh/.aliases
source ~/.config/zsh/.functions

# zsh options
setopt AUTO_CD
setopt CORRECT
setopt SHARE_HISTORY
setopt HIST_NO_STORE
setopt HIST_REDUCE_BLANKS

HISTFILE=~/.config/zsh/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then compinit; else compinit -C; fi

# Completion behavior: case-insensitive matching, arrow-key menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Ghost-text suggestions from history (accept with right arrow or end)
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Atuin: history with the directory and git repo of each command.
# Up arrow shows this directory's history, ctrl+r searches (see config.toml).
# --disable-ai stops `?` from sending the prompt to Atuin's AI service.
if command -v atuin >/dev/null; then
  eval "$(atuin init zsh --disable-ai)"
  # Suggest commands from this directory first, then from anywhere
  _zsh_autosuggest_strategy_atuin_cwd() {
    suggestion=$(ATUIN_QUERY="$1" atuin search --cmd-only --author '$all-user' --limit 1 --search-mode prefix --filter-mode directory 2>/dev/null)
  }
  ZSH_AUTOSUGGEST_STRATEGY=(atuin_cwd atuin)
fi

# Syntax highlighting (must be sourced last)
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Prompt
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
command -v starship >/dev/null && eval "$(starship init zsh)"

# zoxide: `z <partial-name>` jumps to frecent dirs, `zi` for interactive pick
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# 1Password SSH Agent
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# Amp CLI
export PATH="$HOME/.amp/bin:$PATH"

# Entire CLI shell completion
if command -v entire >/dev/null; then
  [[ -f ~/.config/zsh/_entire_completion ]] || entire completion zsh > ~/.config/zsh/_entire_completion
  source ~/.config/zsh/_entire_completion
fi

command -v mise >/dev/null && eval "$(mise activate zsh)"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# PostHog personal API key (annotation:write), read from the keychain on demand.
# Exporting it cost a keychain call per shell and put the key in the
# environment of every process. Callers run:
#   POSTHOG_PERSONAL_API_KEY="$(posthog-key)" apps/mac/scripts/release.sh
posthog-key() {
  security find-generic-password -a "$USER" -s posthog-personal-api-key -w 2>/dev/null
}

# Environment variables
export EDITOR='cursor'
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

# Python
export PATH="$HOME/.local/bin:$PATH"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - --no-rehash)"

# GPG
if command -v gpgconf >/dev/null 2>&1; then
  export GPG_TTY=$(tty)
fi

# FZF
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

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
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# 1Password SSH Agent
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# Amp CLI
export PATH="$HOME/.amp/bin:$PATH"

# Entire CLI shell completion
if [[ ! -f ~/.config/zsh/_entire_completion ]]; then
  entire completion zsh > ~/.config/zsh/_entire_completion
fi
source ~/.config/zsh/_entire_completion

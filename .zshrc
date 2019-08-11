echo -ne "\033]6;1;bg;red;brightness;23\a"
echo -ne "\033]6;1;bg;green;brightness;25\a"
echo -ne "\033]6;1;bg;blue;brightness;25\a"

ZSH=~/.oh-my-zsh
ZSH_THEME="geometry-modified"
ZSH_CUSTOM=~/.ohmyzsh/

HISTCONTROL=ignoredups:ignorespace

alias sudo='sudo '

plugins=(git zsh-completions zsh-autosuggestions pip)

ZSH_CACHE_DIR=$HOME/.oh-my-zsh-cache
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir $ZSH_CACHE_DIR
fi

# l for longform ls
alias l='ls -lh'

source $ZSH/oh-my-zsh.sh
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
autoload -U compinit && compinit

# Color listing
eval $(gdircolors ~/.dir_colors)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Virtualenv activate
activate() {
  source ./$1/bin/activate
}

# creates a directory and cds into it
mkd() {
	mkdir -p "$@" && cd "$@"
}

# Dotfiles git -> dotcfg
alias dotcfg='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export PATH="/usr/local/opt/llvm/bin:$PATH"
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'
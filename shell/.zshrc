# ~/.zshrc: executed by zsh for interactive shells.

# History
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt APPEND_HISTORY
HISTFILE=~/.zsh_history
SAVEHIST=1000

# Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f$ '

# Completion
autoload -Uz compinit && compinit

# Load shared config
if [ -f "$HOME/dotfiles/shell/common.sh" ]; then
  . "$HOME/dotfiles/shell/common.sh"
fi

# Load machine-local overrides (secrets, etc.)
if [ -f "$HOME/.zshrc.local" ]; then
  . "$HOME/.zshrc.local"
fi

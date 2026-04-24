# common.sh — Shared shell config (sourced by .bashrc and .zshrc)

# History
HISTSIZE=1000
HISTFILESIZE=2000

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Alert alias for long running commands (Linux only)
if [ "$(uname)" = "Linux" ]; then
  alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
elif [ "$(uname)" = "Darwin" ]; then
  # Homebrew Neovim (Apple Silicon or Intel)
  if [ -d "/opt/homebrew/bin" ]; then
    export PATH="/opt/homebrew/bin:$PATH"
  fi
fi

# PATH
export PATH="$HOME/.local/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Conda (initialized per-machine, but source shared hook if available)
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
  . "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
  . "$HOME/miniforge3/etc/profile.d/conda.sh"
elif command -v conda &>/dev/null; then
  eval "$(conda shell.$(basename "$SHELL") hook 2>/dev/null)"
fi

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Claude-mem worker
alias claude-mem='bun "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# Secrets — set these per machine in ~/.bashrc.local or ~/.zshrc.local:
#   export LINEAR_API_KEY="..."
#   export DISCORD_WEBHOOK_URL="..."

#!/bin/bash
# setup.sh — Install dotfiles by creating symlinks
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
OS="$(uname)"

echo "=== Dotfiles Setup ==="
echo "OS: $OS"
echo "Dotfiles: $DOTFILES_DIR"
echo ""

# --- Helper ---
link() {
  local src="$1"
  local dst="$2"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    echo "  Backup: $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  Linked: $dst -> $src"
}

# --- Shell ---
echo "[Shell]"
if [ "$OS" = "Linux" ]; then
  link "$DOTFILES_DIR/shell/.bashrc" "$HOME/.bashrc"
  link "$DOTFILES_DIR/shell/.profile" "$HOME/.profile"
elif [ "$OS" = "Darwin" ]; then
  link "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
fi

# --- Git ---
echo "[Git]"
link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
link "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"

# --- WezTerm ---
echo "[WezTerm]"
link "$DOTFILES_DIR/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
link "$DOTFILES_DIR/wezterm/keybinds.lua" "$HOME/.config/wezterm/keybinds.lua"

# --- Claude Code ---
echo "[Claude Code]"
link "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link "$DOTFILES_DIR/claude/hooks/safety-check.sh" "$HOME/.claude/hooks/safety-check.sh"
link "$DOTFILES_DIR/claude/scripts/run-research.sh" "$HOME/.claude/scripts/run-research.sh"
link "$DOTFILES_DIR/claude/scripts/run-task.sh" "$HOME/.claude/scripts/run-task.sh"
for cmd in "$DOTFILES_DIR/claude/commands/"*.md; do
  link "$cmd" "$HOME/.claude/commands/$(basename "$cmd")"
done

# Generate settings.json with correct paths for this machine
echo "  Generating settings.json..."
if [ "$OS" = "Linux" ]; then
  NOTIFY_CMD="pw-play /usr/share/sounds/freedesktop/stereo/complete.oga"
elif [ "$OS" = "Darwin" ]; then
  NOTIFY_CMD="afplay /System/Library/Sounds/Glass.aiff"
fi

cat > "$HOME/.claude/settings.json" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "bash $HOME/.claude/statusline-command.sh"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/hooks/safety-check.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "$NOTIFY_CMD"
          }
        ]
      }
    ]
  },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "claude-mem@thedotmack": true,
    "code-review@claude-plugins-official": true,
    "pr-review-toolkit@claude-plugins-official": true,
    "tdd-guard@tdd-guard": true
  },
  "extraKnownMarketplaces": {
    "superpowers-marketplace": {
      "source": {
        "source": "github",
        "repo": "obra/superpowers-marketplace"
      }
    },
    "thedotmack": {
      "source": {
        "source": "github",
        "repo": "thedotmack/claude-mem"
      }
    },
    "claude-code-plugins": {
      "source": {
        "source": "github",
        "repo": "anthropics/claude-code"
      }
    },
    "tdd-guard": {
      "source": {
        "source": "github",
        "repo": "nizos/tdd-guard"
      }
    }
  }
}
EOF
echo "  Generated: $HOME/.claude/settings.json"

# --- Neovim ---
echo "[Neovim]"
NVIM_REPO="git@github.com:shutouyusei/NvimLazy.git"
if [ -d "$HOME/.config/nvim/.git" ]; then
  echo "  Already cloned. Skipping."
else
  echo "  Cloning nvim config..."
  git clone "$NVIM_REPO" "$HOME/.config/nvim"
fi

# --- Reminder ---
echo ""
echo "=== Done ==="
echo ""
echo "Don't forget to set secrets in your local file:"
if [ "$OS" = "Linux" ]; then
  echo "  ~/.bashrc.local"
elif [ "$OS" = "Darwin" ]; then
  echo "  ~/.zshrc.local"
fi
echo ""
echo "  export LINEAR_API_KEY=\"...\""
echo "  export DISCORD_WEBHOOK_URL=\"...\""

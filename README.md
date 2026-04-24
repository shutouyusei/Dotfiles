# dotfiles

Cross-platform dotfiles managed by [chezmoi](https://www.chezmoi.io/).
Targets **Ubuntu/Debian Linux** and **macOS**.

## What's here

| Path | Purpose |
|---|---|
| `dot_bashrc.tmpl` / `dot_zshrc.tmpl` | Shell rc, branches on OS |
| `dot_config/shell/common.sh` | Shared env + aliases sourced by both shells |
| `dot_config/wezterm/` | WezTerm config |
| `dot_config/git/ignore` | Global git ignore |
| `dot_gitconfig` | Git user config |
| `dot_claude/` | Claude Code config (CLAUDE.md, hooks, scripts, commands, templated settings.json) |
| `.chezmoiexternal.toml` | Pulls `shutouyusei/NvimLazy` into `~/.config/nvim/` at apply time |
| `run_once_before_install-deps.sh.tmpl` | Installs all system packages, Nerd Font, WezTerm, lazygit |

Secrets (LINEAR_API_KEY, DISCORD_WEBHOOK_URL) live in `~/.bashrc.local` / `~/.zshrc.local`
— never tracked. If you later want encrypted secrets in-repo, chezmoi + age is already
wired up (`chezmoi add --encrypt <file>`).

## New-machine bootstrap (one command)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply shutouyusei
```

This will:
1. Install chezmoi into `~/.local/bin`
2. Clone this repo into `~/.local/share/chezmoi`
3. Run `install-deps.sh` (apt on Linux / brew on macOS)
4. Link dotfiles into `$HOME`
5. Clone NvimLazy into `~/.config/nvim`

After that, launch nvim — LazyVim installs plugins; Mason installs LSPs/formatters.

## Day-to-day

```bash
chezmoi edit ~/.bashrc       # edit the source template, not the linked target
chezmoi diff                 # preview changes before applying
chezmoi apply                # apply and push into $HOME
chezmoi git pull             # pull updates from GitHub
chezmoi git -- push          # push local changes up
```

## Recovery

Pre-chezmoi state is preserved on the remote:
- branch `archive-pre-chezmoi`
- tag `archive-pre-chezmoi-YYYYMMDD`

To revert: `git checkout archive-pre-chezmoi`.

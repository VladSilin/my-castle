# my-castle

Dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package | Contents |
|---------|----------|
| `shell` | `.zshrc` |
| `git`   | `.gitconfig` |
| `vim`   | `.vimrc`, `.vim/` (colors, plugins, ftplugin) |
| `tmux`  | `.tmux.conf`, `.tmux/scripts/` |
| `claude`| `.claude/settings.json`, `.claude/statusline.sh` |

## Usage

Install all packages:
```bash
cd ~/Programming/my-castle
stow -t ~ shell git vim tmux claude
```

Install a single package:
```bash
stow -t ~ tmux
```

Uninstall a package:
```bash
stow -D -t ~ claude
```

Re-stow (clean up stale symlinks + re-link):
```bash
stow -R -t ~ shell git vim tmux claude
```

## Not managed here

- `~/.config/nvim/` — separate git repo
- `~/.claude/skills/` — copied from `~/Programming/ai-tools/claude-skills/`
- `~/.vim/plugged/` — managed by vim-plug

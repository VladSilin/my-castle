# my-castle

Dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## How it works

Stow creates symlinks from `~/` pointing into this repo. Each top-level directory is a "package" whose contents mirror the home directory structure. Running `stow -t ~ tmux` makes `~/.tmux.conf` a symlink to `tmux/.tmux.conf` in this repo — edits in either location are the same file.

**How stow chooses the target:** by default stow symlinks into the parent of its working directory. Since the repo lives in `~/Programming/my-castle/`, running plain `stow tmux` would target `~/Programming/` — not what we want. The `-t ~` flag overrides the target to the home directory.

## Packages

| Package | Contents |
|---------|----------|
| `shell` | `.zshrc` |
| `git`   | `.gitconfig` |
| `vim`   | `.vimrc`, `.vim/` (colors, plugins, ftplugin) |
| `tmux`  | `.tmux.conf`, `.tmux/` (scripts, hints), `.claude/settings.local.json` |
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

## Gotchas

**`git config --global` breaks the symlink.** Git writes a temp file and renames it, replacing the symlink with a regular file. After using `git config --global`, re-stow:
```bash
cd ~/Programming/my-castle && stow -R -t ~ git
```

**Atomic writers in general.** Any program that saves by writing a temp file + rename (rather than editing in place) will break the symlink for that file. If a dotfile stops being tracked, check with `ls -la` and re-stow the package.

**Running processes need a restart after first stow.** Programs that loaded config before the symlink swap (e.g. Claude Code reading `settings.json`) won't pick up the new path until restarted.

## Work laptop setup

Clone and stow the universal packages:
```bash
git clone <repo-url> ~/Programming/my-castle
cd ~/Programming/my-castle
stow -t ~ vim tmux
```

Remove existing files that stow will replace before running:
```bash
rm ~/.vimrc ~/.tmux.conf
rm -rf ~/.vim/after ~/.vim/autoload ~/.vim/colors ~/.vim/plugin ~/.vim/syntax ~/.vim/coc-settings.json
rm -rf ~/.tmux/scripts ~/.tmux/hints.txt ~/.tmux/README.md
```

Skip `shell` (work `.zshrc` will differ) and `claude` (not all settings apply). For individual files from skipped packages, symlink manually:
```bash
ln -s ~/Programming/my-castle/claude/.claude/statusline.sh ~/.claude/statusline.sh
```

## Not managed here

- `~/.config/nvim/` — separate git repo
- `~/.claude/skills/` — copied from `~/Programming/ai-tools/claude-skills/`
- `~/.vim/plugged/` — managed by vim-plug

# Tmux Config

## Adding Tmux Hints

Hints live in `.tmux/hints.txt`, one per line. They are shown in a searchable fzf popup via `prefix + ?`.

To add a hint, append a line following this format:

```
<icon> <Category>      <key>  description  • <key>  description
```

Rules:
- Each hint MUST start with a Nerd Font unicode icon (e.g. 󰋼, 󰚩, 󰆼, 󰁨, 󰖯)
- Use consistent spacing: icon, then category name padded to ~16 chars, then key/description pairs separated by ` • `
- Keep hints to a single line

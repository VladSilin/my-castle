# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  #zsh-autosuggestions
  #zsh-syntax-highlighting
  #fast-syntax-highlighting
  #zsh-autocomplete
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


# Terminal Colors
# tmux only advertises 256-color via $TERM; this tells apps (e.g. Claude Code) to use full 24-bit color
export COLORTERM=truecolor
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
# BSD ls colorizes with -G; GNU ls reads -G as "omit group column" and needs
# --color=auto instead, so the same alias silently loses color on Linux.
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -GFh'
else
  alias ls='ls --color=auto -Fh'
fi

# Fix for muted colours in Claude Code
export CLAUDE_CODE_TMUX_TRUECOLOR=1


# Python Stuff
# alias pip=/usr/local/bin/pip3
# alias python=/usr/local/bin/python3
# export NODE_GYP_FORCE_PYTHON=`which python3`


# vim fzf Config
export FZF_DEFAULT_COMMAND='rg --files --follow --hidden'

# fzf shell integration (fuzzy completion and keybindings)
source <(fzf --zsh)

# fzf-git integration (git-specific fuzzy keybindings)
# Download fzf-git.sh if not exists
if [ ! -f ~/.fzf-git.sh ]; then
  curl -fsSL -o ~/.fzf-git.sh https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh
fi
source ~/.fzf-git.sh

# zoxide: frecency-based directory jumping for dirs you've visited before.
#   z <token>   jump to best match (e.g. `z skills`)
#   zi <token>  interactive fzf picker over your dir history
eval "$(zoxide init zsh)"

# fcd: true cross-filesystem directory fuzzy search for dirs you've never visited.
# Walks $HOME with fd, skipping noisy trees, and cd's into the picked result.
fcd() {
  local dir
  dir=$(fd --type d --hidden --follow \
            --exclude .git --exclude node_modules --exclude Library \
            --exclude .Trash --exclude .cache \
            . ~ | fzf --preview 'ls -la {} | head -50') \
    && cd "$dir"
}


# nvim Config
# The `DBUS_SESSION_BUS_ADDRESS` environment variable must be set for Zathura to work with VimTeX; see [2] for details.
# macOS only: $DBUS_LAUNCHD_SESSION_BUS_SOCKET is a launchd thing. On Linux the
# session bus address is already set by the login session — overriding it with
# an empty path breaks every dbus client.
if [[ "$OSTYPE" == darwin* ]]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$DBUS_LAUNCHD_SESSION_BUS_SOCKET"
fi
# [2]: https://github.com/lervag/vimtex/issues/2391


# Aliases
alias doc='docker-compose'
alias docker-destroy-all='docker container stop $(docker container ls -aq) && docker container rm $(docker container ls -aq) && docker rmi $(docker images -a -q)'

alias gitd='git diff --word-diff=color'
alias gitlo='git log --oneline'
alias gitd='git diff --word-diff=color'
alias gitlo='git log --oneline'
alias gitb='git branch'
alias gits='git status'
alias gitA='git add -A'
alias gitc='git commit'
alias gitca='git commit --amend'
alias gitcnv='git commit --no-verify'
alias gitcanv='git commit --amend --no-verify'
alias gitp='git push'
alias gitpf='git push -f'

alias config-zsh='nvim ~/.zshrc'
alias config-tmux='nvim ~/.tmux.conf'
alias ref='~/.tmux/scripts/session-ref.sh'

# Override bare `tmux` to launch the session-create picker
tmux() {
  if [ $# -eq 0 ]; then
    ~/.tmux/scripts/session-create.sh "$PWD"
  else
    command tmux "$@"
  fi
}

# Tag the pane with @agent so the tmux agent-awareness integration can find
# it (cursor-agent's process shows up as plain "node" in tmux, so it can't
# be identified by process name the way Claude's Electron binary can — see
# tmux/.tmux/README.md). Cleared on exit; window reverts to normal
# automatic-rename behavior.
#
# Both `agent` and `cursor-agent` are real, separate symlinks to the same
# binary (~/.local/bin/agent and ~/.local/bin/cursor-agent) — `agent` is
# actually the tool's own canonical name (see its --help usage line), so
# both need wrapping or one silently bypasses tagging entirely.
#
# All tmux calls target -t "$TMUX_PANE" explicitly rather than relying on
# "current window" resolution — that resolves to whatever window the
# attached client is currently *looking at*, not necessarily this pane's
# window (verified: a bare `rename-window`/`set-option -w` issued from a
# background/unfocused pane silently renames/retargets the wrong window).
_cursor_agent_wrapper() {
  local cmd="$1"
  shift
  if [ -n "$TMUX" ]; then
    tmux set-option -p -t "$TMUX_PANE" @agent cursor-agent
    tmux rename-window -t "$TMUX_PANE" cursor-agent
    tmux set-option -w -t "$TMUX_PANE" automatic-rename off
  fi
  command "$cmd" "$@"
  local rc=$?
  if [ -n "$TMUX" ]; then
    tmux set-option -pu -t "$TMUX_PANE" @agent
    tmux set-option -w -t "$TMUX_PANE" automatic-rename on
  fi
  return $rc
}
agent() { _cursor_agent_wrapper agent "$@" }
cursor-agent() { _cursor_agent_wrapper cursor-agent "$@" }

alias config-nvim='cd ~/.config/nvim && nvim'
alias cd-nvim='cd ~/.config/nvim'

alias config-vim='vim ~/.vimrc'

alias lg='lazygit'

# nvm Stuff
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# ---- macOS-only block ----
# Homebrew paths, the Keychain, xcrun and pmset only exist on the Mac. Guarding
# the whole block keeps this file usable verbatim on Linux boxes; without it
# every shell start prints "command not found" for xcrun and security.
if [[ "$OSTYPE" == darwin* ]]; then
  # LLVM Stuff
  export LDFLAGS="-L/opt/homebrew/opt/llvm@12/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/llvm@12/include"

  export PATH="/opt/homebrew/opt/llvm@12/bin:$HOME/.local/bin:$PATH"


  # Haskell Stuff
  [ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" # ghcup-env

  # Fix the Haskell linter install error with "ffitarget_arm64.h"
  export C_INCLUDE_PATH="$(xcrun --show-sdk-path)/usr/include/ffi"


  # OpenRouter (stored in macOS Keychain)
  export OPENROUTER_API_KEY=$(security find-generic-password -a "$USER" -s openrouter -w)


  # Offline access
  subway() {
      sudo pmset -a disablesleep 1
      echo "Sleep fully disabled."
      echo "Now flip Internet Sharing on."
      open "x-apple.systempreferences:com.apple.Sharing-Settings.extension"
  }

  subway-off() {
      sudo pmset -a disablesleep 0
      echo "Sleep re-enabled."
      echo "Flip Internet Sharing off."
      open "x-apple.systempreferences:com.apple.Sharing-Settings.extension"
  }
fi


# ---- SDKMAN (Java / Maven / Gradle version manager) ----
# Manages JDK, Maven, Gradle. `sdk list java`, `sdk use java <ver>`, per-project `.sdkmanrc`.
# This block MUST stay at the very bottom of the file (SDKMAN sets PATH/JAVA_HOME here).
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

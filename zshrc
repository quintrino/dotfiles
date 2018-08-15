#!/bin/zsh
function precmd() {
    [ -d $HOME/.history ] || mkdir -p $HOME/.history
    [ -d $HOME/.history/zsh ] || mkdir -p $HOME/.history/zsh
    echo ": [$(date)] $$ ${USER} ${PWD}\; $(fc -nl | tail -n 1)" >> $HOME/.history/zsh/history-$(date +%Y%m%d)
}



# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export EDITOR=subl

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


function ct () {
    for code ({000..255}) print -P -- "$code: %F{$code} $1 %f"
}

# `gl [<remote>] [<branch>]` git pull
# pull <branch> or the current branch from <remote> or origin
function gl(){
  local remote=${1:-origin}
  local branch=${2:-$(git_current_branch)}
  git pull --no-edit "$remote" "$branch"
}

# `glf [<remote>] [<branch>]` git pull force
# force pull <branch> or the current branch from <remote> or origin
function glf() {
  local remote=${1:-origin}
  local branch=${2:-$(git_current_branch)}
  git fetch "$remote" "$branch" && git reset --hard "$remote"/"$branch"
}

function cc_menu {
  local branch=${1:-$(git_current_branch)}

  if ! defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep -qF "Marketplacer - remote ($branch)"; then
    killall CCMenu
    defaults write net.sourceforge.cruisecontrol.CCMenu Projects "(
      { displayName = $branch; projectName = \"Marketplacer - remote ($branch)\"; serverUrl = \"https://cc.buildkite.com/marketplacer/marketplacer-remote.xml?access_token=$CC_BUILDKITE_TOKEN&branch=$branch\"; },
      $(defaults read net.sourceforge.cruisecontrol.CCMenu Projects | tail -n +2)"
    open -g /Applications/CCMenu.app
  fi
}

export ZSH_PLUGINS_ALIAS_TIPS_REVEAL=1


POWERLEVEL9K_PROMPT_ON_NEWLINE=false
POWERLEVEL9K_RPROMPT_ON_NEWLINE=true

POWERLEVEL9K_VCS_CLEAN_FOREGROUND='black'
POWERLEVEL9K_VCS_CLEAN_BACKGROUND='070'
POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='black'
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='yellow'
POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='black'
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='red'

POWERLEVEL9K_RVM_BACKGROUND="black"
POWERLEVEL9K_RVM_FOREGROUND="009"
POWERLEVEL9K_RVM_VISUAL_IDENTIFIER_COLOR="red"
# POWERLEVEL9K_RUBY_ICON=$'\uF219'
POWERLEVEL9K_OS_ICON_BACKGROUND="blue"
POWERLEVEL9K_APPLE_ICON=$''


# export ZSH_PLUGINS_ALIAS_TIPS_FORCE=1


POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
POWERLEVEL9K_CUSTOM_DIRECT="print -P "%~""

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context custom_direct newline dir chruby rvm vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator command_execution_time background_jobs history battery time)

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

setopt AUTO_PUSHD

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel9k/powerlevel9k"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
 ENABLE_CORRECTION="true"


# Uncomment the following line to display red dots whilst waiting for completion.
 COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  alias-tips
  brew
  bundle
  colorize
  dirhistory
  fast-syntax-highlighting
  gem
  git
  k
  osx
  npm
  # ruby
  sublime
  wd
  up
  z
  zsh-autosuggestions
  zsh_reload
  zsh-syntax-highlighting
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

# ssh
#export SSH_KEY_PATH="~/.ssh/rsa_id"
#zstyle :omz:plugins:ssh-agent identities id_rsa

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias gd='git diff --ignore-all-space --ignore-blank-lines'
alias gl='git log'
#alias wc='cd ~/Projects/hoh/wooCommerce/wc-hoh-connector-bundle'

source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh
# source ~/.profile
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# export PATH=$PATH:/usr/local/opt/go/libexec/bin
# export GOPATH=$(go env GOPATH)




# Alias for: ls -G -lah



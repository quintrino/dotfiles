#!/bin/zsh
function precmd() {
    [ -d $HOME/.history ] || mkdir -p $HOME/.history
    [ -d $HOME/.history/zsh ] || mkdir -p $HOME/.history/zsh
    echo ": [$(date)] $$ ${USER} ${PWD}\; $(fc -nl | tail -n 1)" >> $HOME/.history/zsh/history-$(date +%Y%m%d)
}

setopt append_history
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # add commands to HISTFILE in order of execution
setopt share_history          # share command history data
HISTSIZE=50000
SAVEHIST=10000
HISTFILE=~/.zsh_history     #Where to save history to disk

export CLICOLOR=1
export EDITOR=subl
export ZSH_PLUGINS_ALIAS_TIPS_REVEAL=1
export NVM_LAZY_LOAD=true
export ZPLUG_HOME=/usr/local/opt/zplug

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
POWERLEVEL9K_OS_ICON_BACKGROUND="blue"
POWERLEVEL9K_APPLE_ICON=$''
POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
POWERLEVEL9K_CUSTOM_DIRECT="print -P "%~""

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context custom_direct newline dir chruby rvm vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator command_execution_time background_jobs history battery time)

source $ZPLUG_HOME/init.zsh

zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme
zplug "djui/alias-tips"
zplug "zdharma/fast-syntax-highlighting", from:github
zplug "lukechilds/zsh-nvm"
zplug "plugins/history", from:oh-my-zsh
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

zplug load

source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh

chruby 2.5.1
export GIT_TEMPLATE_DIR=`overcommit --template-dir`
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

fpath=(/usr/local/share/zsh-completions $fpath)
autoload -U compinit
compinit


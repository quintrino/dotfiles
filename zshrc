#!/bin/zsh
function precmd() {
    [ -d $HOME/.history ] || mkdir -p $HOME/.history
    [ -d $HOME/.history/zsh ] || mkdir -p $HOME/.history/zsh
    echo ": [$(date)] $$ ${USER} ${PWD}\; $(fc -nl | tail -n 1)" >> $HOME/.history/zsh/history-$(date +%Y%m%d)
}


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
zplug "plugins/zsh_reload",   from:oh-my-zsh
zplug "lukechilds/zsh-nvm"
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

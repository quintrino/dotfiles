#!/bin/zsh
function precmd() {
    [ -d $HOME/.history ] || mkdir -p $HOME/.history
    [ -d $HOME/.history/zsh ] || mkdir -p $HOME/.history/zsh
    echo ": [$(date)] $$ ${USER} ${PWD}\; $(fc -nl | tail -n 1)" >> $HOME/.history/zsh/history-$(date +%Y%m%d)
}

source /usr/local/share/chruby/chruby.sh
source /usr/local/share/chruby/auto.sh

chruby 2.5.1
export GIT_TEMPLATE_DIR=`overcommit --template-dir`

setopt append_history
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # add commands to HISTFILE in order of execution
setopt share_history          # share command history data
HISTSIZE=50000
SAVEHIST=10000
HISTFILE=~/.zsh_history     #Where to save history to disk

export CLICOLOR=1
export EDITOR=subl
export EXA_GRID_ROWS=8

setopt autopushd

starting_directory=`pwd`
cd $HOME/.dotfiles
git fetch --quiet &>/dev/null &|
if ! git diff --quiet --ignore-submodules HEAD; then
  echo "WARNING: ~/.dotfiles has unsynchronized changes"
fi

cd $starting_directory
unset starting_directory

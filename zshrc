#!/bin/zsh
function precmd() {
    export DIRS=$(pwd | awk '{ sub("/Users/nick.wolf/Code", "~"); print $0 }')
    echo -ne "\e]1;${DIRS/#$HOME/~}\a"
    [ -d $HOME/.history ] || mkdir -p $HOME/.history
    [ -d $HOME/.history/zsh ] || mkdir -p $HOME/.history/zsh
    echo ": [$(date)] $$ ${USER} ${PWD}\; $(fc -nl | tail -n 1)" >> $HOME/.history/zsh/history-$(date +%Y%m%d)
}

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
export EDITOR=edit
export EXA_GRID_ROWS=8
export ASDF_GLOBAL_RUBY=`bat $HOME/.tool-versions | rg ruby`

setopt autopushd
setopt auto_cd

starting_directory=`pwd`
cd $HOME/.dotfiles
git fetch --quiet &>/dev/null &|
if ! git diff --quiet --ignore-submodules HEAD; then
  echo "WARNING: ~/.dotfiles has unsynchronized changes"
fi

cd $starting_directory
unset starting_directory

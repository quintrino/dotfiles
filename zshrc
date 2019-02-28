#!/bin/zsh
function precmd() {
    export DIRS=$(pwd | awk '{ sub("/Users/nick.wolf/Code", "~"); print $0 }')
    echo -ne "\e]1;${DIRS/#$HOME/~}\a"
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
export XDG_CONFIG_HOME="$HOME/.config"
export ASDF_GLOBAL_RUBY=`bat $XDG_CONFIG_HOME/asdf/.tool-versions | rg ruby`
export ASDF_DATA_DIR="$XDG_CONFIG_HOME/asdf"
export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="$XDG_CONFIG_HOME/asdf/tool-versions"

source $HOME/.local/share/zsh/zshrc

setopt autopushd
setopt auto_cd
setopt pushdminus
setopt pushd_ignore_dups

starting_directory=`pwd`
cd $HOME/.dotfiles
git fetch --quiet &>/dev/null &|
if ! git diff --quiet --ignore-submodules HEAD; then
  echo "WARNING: ~/.dotfiles has unsynchronized changes"
fi

cd $starting_directory
unset starting_directory

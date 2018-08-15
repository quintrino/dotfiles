source $HOME/Google\ Drive/Sync/Mac/iTerm/.git-prompt.sh

source $HOME/.profile

PS1="\w\[\033[m\]\$\n\W\$(__git_ps1)\$"

HISTIGNORE="hnote*"
# Used to put notes in a history file
function hnote {
    echo "## NOTE [`date`]: $*" >> $HOME/.history/bash_history-`date +%Y%m%d`
}

# used to keep my history forever
PROMPT_COMMAND="[ -d $HOME/.history ] || mkdir -p $HOME/.history; [ -d $HOME/.history/bash ] || mkdir -p $HOME/.history/bash; echo : [\$(date)] $$ $USER \$PWD\; \$(history 1 | sed -E 's/^[[:space:]]+[0-9]*[[:space:]]+//g') >> $HOME/.history/bash/history-\`date +%Y%m%d\`"



HISTIGNORE="hnote*"
# Used to put notes in a history file
function hnote {
    echo "## NOTE [`date`]: $*" >> $HOME/.history/bash_history-`date +%Y%m%d`
}


export PATH="/usr/local/bin:$PATH"

export PATH="$HOME/.cargo/bin:$PATH"

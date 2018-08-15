[[ -s "$HOME/.local_profile" ]] && source "$HOME/.local_profile" # Load the local .profile

# source $HOME/.aliases

# Python Magic

# export PATH="/usr/local/opt/python/libexec/bin:$PATH"

# NVM Magic


# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm


# RVM Magic

# export PATH="$PATH:$HOME/.rvm/bin"
# [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

chruby ruby-2.5.1

export GIT_TEMPLATE_DIR=`overcommit --template-dir`

function gj () { git branch "$1" && git checkout "$1"; }

function mcd () {
    mkdir -p $1
    cd $1
}



#  export PATH="$HOME/.cargo/bin:$PATH"

